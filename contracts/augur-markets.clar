(define-constant ERR-UNAUTHORIZED (err u801))
(define-constant ERR-EVENT-NOT-FOUND (err u802)) ;; check is in use
(define-constant ERR-EVENT-NOT-OPENED (err u803))
(define-constant ERR-EVENT-NOT-RESOLVED (err u804))
(define-constant ERR-WIN-OUTCOME-NOT-FOUND (err u805))
(define-constant ERR-INVALID-AMOUNT (err u806))
(define-constant ERR-INVALID-COST (err u807))
(define-constant ERR-COST-TOO-HIGH (err u808))
(define-constant ERR-BALANCE-TOO-LOW (err u809))
(define-constant ERR-AMOUNT-TOO-LOW (err u810))

(define-constant SCALE u1000000)
(define-constant E u2718281) ;; e ≈ 2.718281

(define-constant contract-owner principal tx-sender)
(define-data-var token-contract principal tx-sender)
(define-data-var next-event-id uint u0)

(define-map events
  { event-id: uint }
  {
    title: (string-ascii 256),
    desc: (string-ascii 256),
    beta: uint, ;; LMSR sensitivity parameter (scaled)
    ;; 0: init, 1: opened, 2: closed, 3: resolved, 4: rewarded,
    ;;   5: paused, 6: disputed, 7: canceled, 8: returned
    status: uint,
    win-outcome-id: (optional uint)
  }
)
(define-map outcomes
  { event-id: uint, outcome-id: uint }
  { 
    desc: (string-ascii 128),
    share-amount: uint, ;; Total shares issued (scaled)
  }
)
(define-map users
  { event-id: uint, outcome-id: uint, user-id: principal }
  {
    share-amount: uint, ;; Shares holded per user (scaled)
    is-settled: bool,
  }
)



(define-public (create-event (desc (string-ascii 256)) (beta uint) (outcome-descs (list 10 (string-ascii 128))))
  (let
    (
      (event-id (var-get next-event-id))
    )
    (asserts! (is-eq tx-sender contract-owner) ERR-UNAUTHORIZED)
    (map-insert
       events
       { event-id: event-id }
       { desc: desc, resolved: false, resolution-time: none, beta: beta }
    )
    ;;(map set-outcome outcome-descs event-id) ;;wrong?
    (var-set next-event-id (+ event-id u1))
    (ok event-id)
  )
)

;; Helper to set initial outcomes
(define-private (set-outcome (desc (string-ascii 128)) (event-id uint))
  (let
    (
      (outcome-id (len (filter (lambda (k) (is-some (map-get? outcomes { event-id: event-id, outcome-id: k }))) (list u0 u1 u2 u3 u4 u5 u6 u7 u8 u9))))
    )
    (map-insert
      outcomes
      { event-id: event-id, outcome-id: outcome-id }
      { desc: desc, total-shares: u0, winning: none }
    )
  )
)

;;
;; should always fix to 10 choices/outcomes? should specify when create an event?
;;

(define-public (set-event-beta (event-id uint) (n-beta uint))
  (let
    (
      (event (unwrap-panic (get-event event-id)))
    )
    (asserts! (is-eq tx-sender contract-owner) ERR-UNAUTHORIZED)
    (map-set events { event-id: event-id }
      (merge event { beta: n-beta })
    )
    (ok true)
  )
)

(define-public (set-event-status (event-id uint) (n-status uint) (win-outcome-id (optional uint)))
  (let
    (
      (event (unwrap-panic (get-event event-id)))
    )
    (asserts! (is-eq tx-sender contract-owner) ERR-UNAUTHORIZED)
    (asserts! (or (not (is-eq n-status u3)) (is-some win-outcome-id)) ERR-WIN-OUTCOME-NOT-FOUND)
    (map-set events { event-id: event-id }
      (if (is-eq n-status 3)
        (merge event { status: n-status, win-outcome-id: win-outcome-id })
        (merge event { status: n-status })
      )
    )
    (ok true)
  )
)

(define-public (buy-shares (event-id uint) (outcome-id uint) (amount uint))
  (let
    (
      (event (unwrap-panic (get-event event-id)))
      (beta (get beta event))
      (qqbs (get-qqbs event-id beta))
      (cost (get-delta-cost beta qqbs outcome-id true amount))
      (outcome (unwrap-panic (get-outcome event-id outcome-id)))
      (user (default-to
        { share-amount: u0 }
        (get-user event-id outcome-id tx-sender)
      ))
      (balance (unwrap-panic (get-balance tx-sender)))
    )
    (asserts! (is-eq (get status event) 1) ERR-EVENT-NOT-OPENED)
    (asserts! (is-amount-valid amount) ERR-INVALID-AMOUNT)
    (asserts! (> cost u0) ERR-INVALID-COST)
    (asserts! (<= cost balance) ERR-BALANCE-TOO-LOW)
    (try! (transfer cost tx-sender contract-owner none))
    (map-set outcomes { event-id: event-id, outcome-id: outcome-id }
      (merge outcome { share-amount: (+ (get share-amount outcome) amount) })
    )
    (map-set users { event-id: event-id, outcome-id: outcome-id, user-id: tx-sender }
      (merge user { share-amount: (+ (get share-amount user) amount) })
    )
    (ok { cost: cost })
  )
)

(define-public (buy-amap-shares (event-id uint) (outcome-id uint) (max-cost uint))
  (let
    (
      (event (unwrap-panic (get-event event-id)))
      (beta (get beta event))
      (qqbs (get-qqbs event-id beta))
      (amount (get-delta-amount beta qqbs outcome-id max-cost))
      (cost (get-delta-cost beta qqbs outcome-id true amount))
      (outcome (unwrap-panic (get-outcome event-id outcome-id)))
      (user (default-to
        { share-amount: u0 }
        (get-user event-id outcome-id tx-sender)
      ))
      (balance (unwrap-panic (get-balance tx-sender)))
    )
    (asserts! (is-eq (get status event) 1) ERR-EVENT-NOT-OPENED)
    (asserts! (is-amount-valid amount) ERR-INVALID-AMOUNT)
    (asserts! (> cost u0) ERR-INVALID-COST)
    (asserts! (<= cost max-cost) ERR-COST-TOO-HIGH)
    (asserts! (<= cost balance) ERR-BALANCE-TOO-LOW)
    (try! (transfer cost tx-sender contract-owner none))
    (map-set outcomes { event-id: event-id, outcome-id: outcome-id }
      (merge outcome { share-amount: (+ (get share-amount outcome) amount) })
    )
    (map-set users { event-id: event-id, outcome-id: outcome-id, user-id: tx-sender }
      (merge user { share-amount: (+ (get share-amount user) amount) })
    )
    (ok { amount: amount, cost: cost })
  )
)

(define-public (sell-shares (event-id uint) (outcome-id uint) (amount uint))
  (let
    (
      (event (unwrap-panic (get-event event-id)))
      (beta (get beta event))
      (qqbs (get-qqbs event-id beta))
      (cost (get-delta-cost beta qqbs outcome-id false amount))
      (outcome (unwrap-panic (get-outcome event-id outcome-id)))
      (user (unwrap-panic (get-user event-id outcome-id tx-sender)))
    )
    (asserts! (is-eq (get status event) 1) ERR-EVENT-NOT-OPENED)
    (asserts! (is-amount-valid amount) ERR-INVALID-AMOUNT)
    (asserts! (> cost u0) ERR-INVALID-COST)
    (asserts! (<= amount (get share-amount user)) ERR-AMOUNT-TOO-LOW)
    (try! (transfer cost contract-owner tx-sender none))
    (map-set outcomes { event-id: event-id, outcome-id: outcome-id }
      (merge outcome { share-amount: (- (get share-amount outcome) amount) })
    )
    (map-set users { event-id: event-id, outcome-id: outcome-id, user-id: tx-sender }
      (merge user { share-amount: (- (get share-amount user) amount) })
    )
    (ok { cost: cost })
  )
)

(define-pubilc (claim-reward (event-id uint))
  (let
    (
      (event (unwrap-panic (get-event event-id)))
      (status (get status event))
      (win-outcome-id (unwrap-panic (get win-outcome-id event)))
      (user (unwrap-panic (get-user event-id win-outcome-id tx-sender)))
      (amount (get share-amount user))
      (is-settled (get is-settled user))
    )
    (asserts! (is-eq status 3) ERR-EVENT-NOT-RESOLVED)
    (asserts! (is-eq is-settled false) ERR-)
    (try! (transfer amount contract-owner tx-sender none))
    (map-set users { event-id: event-id, outcome-id: win-outcome-id, user-id: tx-sender }
      (merge user { is-settled: true })
    )
    (ok { reward: amount })
  )
)

(define-private (pay-reward (winner { event-id: uint, outcome-id: uint, user-id: principal}))
  (let
    (
      (event-id (get event-id winner))
      (outcome-id (get outcome-id winner))
      (user-id (get user-id winner))
      (event (unwrap-panic (get-event event-id)))
      (status (get status event))
      (win-outcome-id (unwrap-panic (get win-outcome-id event)))
      (user (unwrap-panic (get-user event-id win-outcome-id tx-sender)))
      (amount (get share-amount user))
      (is-settled (get is-settled user))
    )
    (asserts! (is-eq status 3) ERR-EVENT-NOT-RESOLVED)
    (asserts! (is-eq is-settled false) ERR-)
    (try! (transfer amount contract-owner user-id none))
    (map-set users { event-id: event-id, outcome-id: win-outcome-id, user-id: user-id }
      (merge user { is-settled: true })
    )
  )
)
(define-public (pay-rewards (winners (list 200 { event-id: uint, outcome-id: uint, user-id: principal })))
  (begin
    (asserts! (is-eq tx-sender contract-owner) ERR-UNAUTHORIZED)
    (fold check-err (map pay-reward winners) (ok true))
  )
)

(define-private (refund-fund (user { event-id: uint, outcome-id: uint, user-id: principal}))

)
(define-public (refund-funds (users (list 200 { event-id: uint, outcome-id: uint, user-id: principal })))
  (begin
    (asserts! (is-eq tx-sender contract-owner) ERR-UNAUTHORIZED)
    (fold check-err (map refund-fund users) (ok true))
  )
)

(define-public (set-token-contract (new-contract principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) ERR-UNAUTHORIZED)
    (var-set token-contract new-contract)
    (ok true)
  )
)

;; ---------------------------------------------------------
;; LMSR
;; ---------------------------------------------------------

;; y = ∑e^(q_i / b)
(define-private (get-sum-exp-inner (acc uint) (qqb { id: uint, q: uint, qb: uint }))
  (+ acc (exp (get qb qqb)))
)
(define-read-only (get-sum-exp qqbs (list 10 { id: uint, q: uint: qb: uint }))
  (fold get-sum-exp-inner qqbs u0)
)

;; C = b * ln(∑e^(q_i / b))
(define-read-only (get-cost (beta uint) (qqbs (list 10 { id: uint, q: uint, qb: uint })))
  (let
    (
      (sum-exp (get-sum-exp qqbs))
    )
    (/ (* beta (ln sum-exp)) SCALE)
  )
)

;; ΔC = C(new) - C(current)
(define-read-only (get-delta-cost (beta uint) (qqbs (list 10 { id: uint, q: uint, qb: uint })) (id uint) (is-buy bool) (amount uint))
  (let
    (
      (n-qqbs (get-new-qqbs beta qqbs id is-buy amount))
      (cost-before (get-cost beta qqbs))
      (cost-after (get-cost beta n-qqbs))
    )
    (if (<= cost-after cost-before)
      u0
      (- cost-after cost-before)
    )
  )
)

;; Δq = b * ln(S * e^(C / b) - S + e^(q_k / b)) - q_k, S = ∑e^(q_i / b)
(define-read-only (get-delta-amount (beta uint) (qqbs (list 10 { id: uint, q: uint, qb: uint })) (id uint) (max-cost uint))
  (let
    (
      (sum-exp (get-sum-exp qqbs))
      (qqb (unwrap-panic (element-at? qqbs id)))
      (qk (get q qqb))
      (qkb (get qb qqb))
      (exp-qkb (exp qkb))
      (exp-cb (exp (/ (* max-cost SCALE) beta)))
      (i-term (- (+ (/ (* sum-exp exp-cb) SCALE) exp-qkb) sum-exp))
    )
    (if (< i-term u1)
      u0
      (let
        (
          (l-term (ln i-term))
          (n-qk (/ (* beta l-term) SCALE))
        )
        (if (<= n-qk qk)
          u0
          (* (/ (- n-qk qk) SCALE) SCALE) ;; whole shares, no frac
        )
      )
    )
  )
)

;; C_i = e^(q_i / b) / ∑e^(q / b)
(define-read-only (get-share-cost (sum-exp uint) (qqb { id: uint, q: uint, qb: uint}))
  (let
    (
      (qkb (get qb qqb))
      (exp-qkb (exp qkb))
    )
    (/ (* exp-qkb SCALE) sum-exp)
  )
)

;; ---------------------------------------------------------
;; Read helpers
;; ---------------------------------------------------------

;; Validate amount > 0 and no frac
(define-read-only (is-amount-valid (amount uint))
  (let
    (
      (frac (mod amount SCALE))
    )
    (and (> amount u0) (is-eq frac u0))
  )
)

;; Get event
(define-read-only (get-event (event-id uint))
  (map-get? events { event-id: event-id })
)

;; Get outcome
(define-read-only (get-outcome (event-id uint) (outcome-id uint))
  (map-get? outcomes { event-id: event-id, outcome-id: outcome-id })
)

;; Get user
(define-read-only (get-user (event-id uint) (outcome-id uint) (user-id principal))
  (map-get? users { event-id: event-id, outcome-id: outcome-id, user-id: user-id })
)

;; Get user in-game money balance
(define-read-only (get-balance (user-id principal))
  (contract-call? (var-get token-contract) get-balance user-id)
)

;; Get q and q/b for each event outcome
(define-private (get-qqb (id uint) (outcome { desc: (string-ascii 128), share-amount: uint }) (beta uint))
  {
    id: id,
    q: (get share-amount outcome),
    qb: (/ (* (get share-amount outcome) SCALE) beta)
  }
)
(define-read-only (get-qqbs (event-id uint) (beta uint))
  (let
    (
      (r-outcomes (map
        get-outcome
        (list event-id event-id event-id event-id event-id event-id event-id event-id event-id event-id)
        (list u0 u1 u2 u3 u4 u5 u6 u7 u8 u9)
      ))
      (f-outcomes (filter is-some r-outcomes))
      (u-outcomes (map unwrap-panic f-outcomes))
    )
    (map get-qqb
      (list u0 u1 u2 u3 u4 u5 u6 u7 u8 u9)
      u-outcomes
      (list beta beta beta beta beta beta beta beta beta beta)
    )
  )
)

;; Get new updated q and q/b based on the current ones
(define-private (get-new-qqb (qqb { id: uint, q: uint, qb: uint }))
  { id: (get id qqb), q: (get q qqb), qb: (get qb qqb) }
)
(define-read-only (get-new-qqbs (beta uint) (qqbs (list 10 { id: uint, q: uint, qb: uint })) (id uint) (is-buy bool) (amount uint))
  (let
    (
      (c-qqbs (map get-new-qqb qqbs))
      (qqb (unwrap-panic (element-at? c-qqbs id)))
      (q (get q qqb))
      (n-q (if is-buy (+ q amount) (if (> q amount) (- q amount) u0)))
      (n-qqb { id: id, q: n-q, qb: (/ (* n-q SCALE) beta) })
    )
    (unwrap-panic (replace-at? c-qqbs id n-qqb))
  )
)

;; Get beta and outcomes
(define-read-only (get-b-and-ocs (event-id uint) (outcome-ids (list 10 uint)))
  (let
    (
      (event (unwrap-panic (get-event event-id)))
      (beta (get beta event))
      (ocs (map
        get-outcome
        (list event-id event-id event-id event-id event-id event-id event-id event-id event-id event-id)
        outcome-ids
      ))
    )
    { beta: beta, ocs: ocs }
  )
)

;; Get current share cost for each event outcome
(define-read-only (get-share-costs (event-id uint))
  (let
    (
      (event (unwrap-panic (get-event event-id)))
      (beta (get beta event))
      (qqbs (get-qqbs event-id beta))
      (sum-exp (get-sum-exp qqbs))
    )
    (map
      get-share-cost
      (list sum-exp sum-exp sum-exp sum-exp sum-exp sum-exp sum-exp sum-exp sum-exp sum-exp)
      qqbs
    )
  )
)

;; ---------------------------------------------------------
;; Perform helpers
;; ---------------------------------------------------------

(define-private (transfer (amount uint) (sender principal) (recipient principal) (memo (optional (buff 34))))
  (contract-call? (var-get token-contract) transfer amount sender recipient memo)
)

(define-private (check-err (result (response bool uint)) (prior (response bool uint)))
  (match prior ok-value result err-value (err err-value))
)

;; ---------------------------------------------------------
;; Exponential
;; ---------------------------------------------------------

(define-map exp-lookup { x: uint } { value: uint })
(begin
  (map-insert exp-lookup { x: u0 } { value: u1000000 }) ;; e^0
  (map-insert exp-lookup { x: u500000 } { value: u1648721 }) ;; e^0.5
  (map-insert exp-lookup { x: u1000000 } { value: u2718281 }) ;; e^1
  (map-insert exp-lookup { x: u1500000 } { value: u4481689 }) ;; e^1.5
  (map-insert exp-lookup { x: u2000000 } { value: u7389056 }) ;; e^2
  (map-insert exp-lookup { x: u2500000 } { value: u12182494 }) ;; e^2.5
  (map-insert exp-lookup { x: u3000000 } { value: u20085536 }) ;; e^3
  (map-insert exp-lookup { x: u4000000 } { value: u54598150 }) ;; e^4
  (map-insert exp-lookup { x: u5000000 } { value: u148413159 }) ;; e^5
  (map-insert exp-lookup { x: u6000000 } { value: u403428793 }) ;; e^6
  (map-insert exp-lookup { x: u7000000 } { value: u1096633158 }) ;; e^7
  (map-insert exp-lookup { x: u8000000 } { value: u2980957987 }) ;; e^8
  (map-insert exp-lookup { x: u9000000 } { value: u8103083928 }) ;; e^9
  (map-insert exp-lookup { x: u11000000 } { value: u59874141715 }) ;; e^11
  (map-insert exp-lookup { x: u13000000 } { value: u442413392009 }) ;; e^13
  (map-insert exp-lookup { x: u15000000 } { value: u3269017372472 }) ;; e^15
  (map-insert exp-lookup { x: u18000000 } { value: u65699969137434 })  ;; e^18
  (map-insert exp-lookup { x: u21000000 } { value: u1315011106939008 }) ;; e^21
  (map-insert exp-lookup { x: u30000000 } { value: u10686474581524000 }) ;; e^30
)

(define-private (get-exp-lower (x uint))
  (if (>= x u30000000) u30000000
    (if (>= x u21000000) u21000000
      (if (>= x u18000000) u18000000
        (if (>= x u15000000) u15000000
          (if (>= x u13000000) u13000000
            (if (>= x u11000000) u11000000
              (if (>= x u9000000) u9000000
                (if (>= x u8000000) u8000000
                  (if (>= x u7000000) u7000000
                    (if (>= x u6000000) u6000000
                      (if (>= x u5000000) u5000000
                        (if (>= x u4000000) u4000000
                          (if (>= x u3000000) u3000000
                            (if (>= x u2500000) u2500000
                              (if (>= x u2000000) u2000000
                                (if (>= x u1500000) u1500000
                                  (if (>= x u1000000) u1000000
                                    (if (>= x u500000) u500000
                                      u0)))))))))))))))))

(define-private (get-exp-upper (x uint))
  (if (<= x u0) u0
    (if (<= x u500000) u500000
      (if (<= x u1000000) u1000000
        (if (<= x u1500000) u1500000
          (if (<= x u2000000) u2000000
            (if (<= x u2500000) u2500000
              (if (<= x u3000000) u3000000
                (if (<= x u4000000) u4000000
                  (if (<= x u5000000) u5000000
                    (if (<= x u6000000) u6000000
                      (if (<= x u7000000) u7000000
                        (if (<= x u8000000) u8000000
                          (if (<= x u9000000) u9000000
                            (if (<= x u11000000) u11000000
                              (if (<= x u13000000) u13000000
                                (if (<= x u15000000) u15000000
                                  (if (<= x u18000000) u18000000
                                    (if (<= x u21000000) u21000000
                                      u30000000)))))))))))))))))

(define-read-only (exp (x uint))
  (let ((lower-x (get-exp-lower x))
        (upper-x (get-exp-upper x))
        (lower-val (get value (unwrap-panic (map-get? exp-lookup { x: lower-x }))))
        (upper-val (get value (unwrap-panic (map-get? exp-lookup { x: upper-x })))))
    (+ floor-val (/ (* (- upper-val lower-val) (- x lower-x)) (- upper-x lower-x)))
  )
)

;; ---------------------------------------------------------
;; Natural logarithm
;; ---------------------------------------------------------

(define-map ln-lookup { x: uint } { value: uint })
(begin
  (map-insert ln-lookup { x: u1000000 } { value: u0 }) ;; ln(1)
  (map-insert ln-lookup { x: u2000000 } { value: u693147 }) ;; ln(2)
  (map-insert ln-lookup { x: u3000000 } { value: u1098616 }) ;; ln(3)
  (map-insert ln-lookup { x: u4000000 } { value: u1386294 }) ;; ln(4)
  (map-insert ln-lookup { x: u5000000 } { value: u1609438 }) ;; ln(5)
  (map-insert ln-lookup { x: u10000000 } { value: u2302585 }) ;; ln(10)
  (map-insert ln-lookup { x: u15000000 } { value: u2708050 }) ;; ln(15)
  (map-insert ln-lookup { x: u20000000 } { value: u2995732 }) ;; ln(20)
  (map-insert ln-lookup { x: u30000000 } { value: u3401192 }) ;; ln(30)
  (map-insert ln-lookup { x: u50000000 } { value: u3912023 }) ;; ln(50)
  (map-insert ln-lookup { x: u100000000 } { value: u4605170 }) ;; ln(100)
  (map-insert ln-lookup { x: u200000000 } { value: u5298317 }) ;; ln(200)
  (map-insert ln-lookup { x: u300000000 } { value: u5703777 }) ;; ln(300)
  (map-insert ln-lookup { x: u500000000 } { value: u6214602 }) ;; ln(500)
  (map-insert ln-lookup { x: u1000000000 } { value: u6907755 }) ;; ln(1000)
  (map-insert ln-lookup { x: u10000000000 } { value: u9210340 }) ;; ln(10000)
  (map-insert ln-lookup { x: u100000000000 } { value: u11512925 }) ;; ln(100000)
  (map-insert ln-lookup { x: u1000000000000 } { value: u13815511 }) ;; ln(1000000)
  (map-insert ln-lookup { x: u10000000000000 } { value: u16118095 }) ;; ln(10000000)
                            ;;106864745815240000 <- max from e^30 * 10 outcomes
)

(define-private (get-ln-lower (x uint))
  (if (>= x u10000000000000) u10000000000000
    (if (>= x u1000000000000) u1000000000000
      (if (>= x u100000000000) u100000000000
        (if (>= x u10000000000) u10000000000
          (if (>= x u1000000000) u1000000000
            (if (>= x u500000000) u500000000
              (if (>= x u300000000) u300000000
                (if (>= x u200000000) u200000000
                  (if (>= x u100000000) u100000000
                    (if (>= x u50000000) u50000000
                      (if (>= x u30000000) u30000000
                        (if (>= x u20000000) u20000000
                          (if (>= x u15000000) u15000000
                            (if (>= x u10000000) u10000000
                              (if (>= x u5000000) u5000000
                                (if (>= x u4000000) u4000000
                                  (if (>= x u3000000) u300000
                                    (if (>= x u2000000) u2000000
                                      u1000000)))))))))))))))))))

(define-private (get-ln-upper (x uint))
  (if (<= x u1000000) u1000000
    (if (<= x u2000000) u2000000
      (if (<= x u3000000) u3000000
        (if (<= x u4000000) u4000000
          (if (<= x u5000000) u5000000
            (if (<= x u10000000) u10000000
              (if (<= x u15000000) u15000000
                (if (<= x u20000000) u20000000
                  (if (<= x u30000000) u30000000
                    (if (<= x u50000000) u50000000
                      (if (<= x u100000000) u100000000
                        (if (<= x u200000000) u200000000
                          (if (<= x u300000000) u300000000
                            (if (<= x u500000000) u500000000
                              (if (<= x u1000000000) u1000000000
                                (if (<= x u10000000000) u10000000000
                                  (if (<= x u100000000000) u100000000000
                                    (if (<= x u1000000000000) u1000000000000
                                      u10000000000000)))))))))))))))))))

(define-read-only (ln (x uint))
  (let ((lower-x (get-ln-lower x))
        (upper-x (get-ln-upper x))
        (lower-val (get value (unwrap-panic (map-get? ln-lookup { x: lower-x }))))
        (upper-val (get value (unwrap-panic (map-get? ln-lookup { x: upper-x })))))
    (+ floor-val (/ (* (- upper-val lower-val) (- x lower-x)) (- upper-x lower-x)))
  )
)
