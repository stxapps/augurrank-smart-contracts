(define-constant ERR-UNAUTHORIZED (err u801))

(define-constant ERR-EVENT-NOT-FOUND (err u811))
(define-constant ERR-OUTCOME-NOT-FOUND (err u812))
(define-constant ERR-USER-NOT-FOUND (err u813))
(define-constant ERR-BALANCE-NOT-FOUND (err u814))
(define-constant ERR-WIN-OUTCOME-NOT-FOUND (err u815))

(define-constant ERR-INVALID-WIN-OUTCOME-ID (err u821))
(define-constant ERR-INVALID-AMOUNT (err u822))
(define-constant ERR-INVALID-COST (err u823))

(define-constant ERR-EVENT-NOT-OPENED (err u831))
(define-constant ERR-EVENT-NOT-RESOLVED (err u832))
(define-constant ERR-EVENT-NOT-CANCELED (err u833))

(define-constant ERR-COST-TOO-HIGH (err u841))
(define-constant ERR-COST-TOO-LOW (err u842))
(define-constant ERR-BALANCE-TOO-LOW (err u843))
(define-constant ERR-SHARES-TOO-LOW (err u844))
(define-constant ERR-ALREADY-SETTLED (err u845))

(define-constant SCALE u1000000)
(define-constant E u2718281) ;; e ~ 2.718281

(define-constant contract-owner tx-sender)
(define-data-var next-event-id uint u0)

(define-map events
  { event-id: uint }
  {
    title: (string-ascii 256),
    desc: (string-ascii 256),
    beta: uint, ;; LMSR sensitivity parameter (scaled)
    ;; 0: init, 1: opened, 2: closed, 3: resolved, 4: paused, 5: disputed, 6: canceled
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

(define-public (create-event (title (string-ascii 256)) (desc (string-ascii 256)) (beta uint) (status uint) (win-outcome-id (optional uint)) (e-outcomes (list 10 { desc: (string-ascii 128), share-amount: uint })))
  (let
    (
      (event-id (var-get next-event-id))
    )
    (asserts! (is-eq tx-sender contract-owner) ERR-UNAUTHORIZED)
    (map-insert
       events
       { event-id: event-id }
       { title: title, desc: desc, beta: beta, status: status, win-outcome-id: win-outcome-id }
    )
    (map
      insert-outcome
      (list event-id event-id event-id event-id event-id event-id event-id event-id event-id event-id)
      (list u0 u1 u2 u3 u4 u5 u6 u7 u8 u9)
      e-outcomes
    )
    (var-set next-event-id (+ event-id u1))
    (ok event-id)
  )
)

(define-public (set-event-beta (event-id uint) (n-beta uint))
  (let
    (
      (event (unwrap! (get-event event-id) ERR-EVENT-NOT-FOUND))
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
      (event (unwrap! (get-event event-id) ERR-EVENT-NOT-FOUND))
    )
    (asserts! (is-eq tx-sender contract-owner) ERR-UNAUTHORIZED)
    (asserts! (or (not (is-eq n-status u3)) (is-some win-outcome-id)) ERR-INVALID-WIN-OUTCOME-ID)
    (map-set events { event-id: event-id }
      (merge event { status: n-status, win-outcome-id: win-outcome-id })
    )
    (ok true)
  )
)

(define-public (buy-shares-a (event-id uint) (outcome-id uint) (amt1 uint) (max-cost uint))
  (let
    (
      (event (unwrap! (get-event event-id) ERR-EVENT-NOT-FOUND))
      (beta (get beta event))
      (qqbs (get-qqbs event-id beta))
      (cost1 (get-delta-cost beta qqbs outcome-id true amt1))
    )
    (asserts! (is-eq (get status event) u1) ERR-EVENT-NOT-OPENED)
    (asserts! (is-amount-valid amt1) ERR-INVALID-AMOUNT)
    (asserts! (> cost1 u0) ERR-INVALID-COST)
    (if (<= cost1 max-cost)
      (buy-shares event-id outcome-id amt1 cost1)
      ERR-COST-TOO-HIGH
    )
  )
)
(define-public (buy-shares-b (event-id uint) (outcome-id uint) (amt1 uint) (amt2 uint) (max-cost uint))
  (let
    (
      (event (unwrap! (get-event event-id) ERR-EVENT-NOT-FOUND))
      (beta (get beta event))
      (qqbs (get-qqbs event-id beta))
      (cost1 (get-delta-cost beta qqbs outcome-id true amt1))
    )
    (asserts! (is-eq (get status event) u1) ERR-EVENT-NOT-OPENED)
    (asserts! (is-amount-valid amt1) ERR-INVALID-AMOUNT)
    (asserts! (> cost1 u0) ERR-INVALID-COST)
    (if (<= cost1 max-cost)
      (buy-shares event-id outcome-id amt1 cost1)
      (let
        (
          (cost2 (get-delta-cost beta qqbs outcome-id true amt2))
        )
        (asserts! (is-amount-valid amt2) ERR-INVALID-AMOUNT)
        (asserts! (> cost2 u0) ERR-INVALID-COST)
        (if (<= cost2 max-cost)
          (buy-shares event-id outcome-id amt2 cost2)
          ERR-COST-TOO-HIGH
        )
      )
    )
  )
)
(define-public (buy-shares-c (event-id uint) (outcome-id uint) (amt1 uint) (amt2 uint) (amt3 uint) (max-cost uint))
  (let
    (
      (event (unwrap! (get-event event-id) ERR-EVENT-NOT-FOUND))
      (beta (get beta event))
      (qqbs (get-qqbs event-id beta))
      (cost1 (get-delta-cost beta qqbs outcome-id true amt1))
    )
    (asserts! (is-eq (get status event) u1) ERR-EVENT-NOT-OPENED)
    (asserts! (is-amount-valid amt1) ERR-INVALID-AMOUNT)
    (asserts! (> cost1 u0) ERR-INVALID-COST)
    (if (<= cost1 max-cost)
      (buy-shares event-id outcome-id amt1 cost1)
      (let
        (
          (cost2 (get-delta-cost beta qqbs outcome-id true amt2))
        )
        (asserts! (is-amount-valid amt2) ERR-INVALID-AMOUNT)
        (asserts! (> cost2 u0) ERR-INVALID-COST)
        (if (<= cost2 max-cost)
          (buy-shares event-id outcome-id amt2 cost2)
          (let
            (
              (cost3 (get-delta-cost beta qqbs outcome-id true amt3))
            )
            (asserts! (is-amount-valid amt3) ERR-INVALID-AMOUNT)
            (asserts! (> cost3 u0) ERR-INVALID-COST)
            (if (<= cost2 max-cost)
              (buy-shares event-id outcome-id amt3 cost3)
              ERR-COST-TOO-HIGH
            )
          )
        )
      )
    )
  )
)

(define-public (sell-shares-a (event-id uint) (outcome-id uint) (amt1 uint) (min-cost uint))
  (let
    (
      (event (unwrap! (get-event event-id) ERR-EVENT-NOT-FOUND))
      (beta (get beta event))
      (qqbs (get-qqbs event-id beta))
      (cost1 (get-delta-cost beta qqbs outcome-id false amt1))
    )
    (asserts! (is-eq (get status event) u1) ERR-EVENT-NOT-OPENED)
    (asserts! (is-amount-valid amt1) ERR-INVALID-AMOUNT)
    (asserts! (> cost1 u0) ERR-INVALID-COST)
    (if (>= cost1 min-cost)
      (sell-shares event-id outcome-id amt1 cost1)
      ERR-COST-TOO-LOW
    )
  )
)
(define-public (sell-shares-b (event-id uint) (outcome-id uint) (amt1 uint) (amt2 uint) (min-cost uint))
  (let
    (
      (event (unwrap! (get-event event-id) ERR-EVENT-NOT-FOUND))
      (beta (get beta event))
      (qqbs (get-qqbs event-id beta))
      (cost1 (get-delta-cost beta qqbs outcome-id false amt1))
    )
    (asserts! (is-eq (get status event) u1) ERR-EVENT-NOT-OPENED)
    (asserts! (is-amount-valid amt1) ERR-INVALID-AMOUNT)
    (asserts! (> cost1 u0) ERR-INVALID-COST)
    (if (>= cost1 min-cost)
      (sell-shares event-id outcome-id amt1 cost1)
      (let
        (
          (cost2 (get-delta-cost beta qqbs outcome-id false amt2))
        )
        (asserts! (is-amount-valid amt2) ERR-INVALID-AMOUNT)
        (asserts! (> cost2 u0) ERR-INVALID-COST)
        (if (>= cost2 min-cost)
          (sell-shares event-id outcome-id amt2 cost2)
          ERR-COST-TOO-LOW
        )
      )
    )
  )
)
(define-public (sell-shares-c (event-id uint) (outcome-id uint) (amt1 uint) (amt2 uint) (amt3 uint) (min-cost uint))
  (let
    (
      (event (unwrap! (get-event event-id) ERR-EVENT-NOT-FOUND))
      (beta (get beta event))
      (qqbs (get-qqbs event-id beta))
      (cost1 (get-delta-cost beta qqbs outcome-id false amt1))
    )
    (asserts! (is-eq (get status event) u1) ERR-EVENT-NOT-OPENED)
    (asserts! (is-amount-valid amt1) ERR-INVALID-AMOUNT)
    (asserts! (> cost1 u0) ERR-INVALID-COST)
    (if (>= cost1 min-cost)
      (sell-shares event-id outcome-id amt1 cost1)
      (let
        (
          (cost2 (get-delta-cost beta qqbs outcome-id false amt2))
        )
        (asserts! (is-amount-valid amt2) ERR-INVALID-AMOUNT)
        (asserts! (> cost2 u0) ERR-INVALID-COST)
        (if (>= cost2 min-cost)
          (sell-shares event-id outcome-id amt2 cost2)
          (let
            (
              (cost3 (get-delta-cost beta qqbs outcome-id false amt3))
            )
            (asserts! (is-amount-valid amt3) ERR-INVALID-AMOUNT)
            (asserts! (> cost3 u0) ERR-INVALID-COST)
            (if (>= cost3 min-cost)
              (sell-shares event-id outcome-id amt3 cost3)
              ERR-COST-TOO-LOW
            )
          )
        )
      )
    )
  )
)

(define-public (claim-reward (event-id uint))
  (let
    (
      (event (unwrap! (get-event event-id) ERR-EVENT-NOT-FOUND))
      (status (get status event))
      (win-outcome-id (unwrap! (get win-outcome-id event) ERR-WIN-OUTCOME-NOT-FOUND))
      (user (unwrap! (get-user event-id win-outcome-id tx-sender) ERR-USER-NOT-FOUND))
      (amount (get share-amount user))
      (is-settled (get is-settled user))
    )
    (asserts! (is-eq status u3) ERR-EVENT-NOT-RESOLVED)
    (asserts! (> amount u0) ERR-INVALID-AMOUNT)
    (asserts! (is-eq is-settled false) ERR-ALREADY-SETTLED)
    (try! (transfer amount contract-owner tx-sender none))
    (map-set users { event-id: event-id, outcome-id: win-outcome-id, user-id: tx-sender }
      (merge user { is-settled: true })
    )
    (ok { reward: amount })
  )
)

(define-public (pay-reward (key { event-id: uint, user-id: principal}))
  (let
    (
      (event-id (get event-id key))
      (user-id (get user-id key))
      (event (unwrap! (get-event event-id) ERR-EVENT-NOT-FOUND))
      (status (get status event))
      (win-outcome-id (unwrap! (get win-outcome-id event) ERR-WIN-OUTCOME-NOT-FOUND))
      (user (unwrap! (get-user event-id win-outcome-id user-id) ERR-USER-NOT-FOUND))
      (amount (get share-amount user))
      (is-settled (get is-settled user))
    )
    (asserts! (is-eq status u3) ERR-EVENT-NOT-RESOLVED)
    (asserts! (> amount u0) ERR-INVALID-AMOUNT)
    (asserts! (is-eq is-settled false) ERR-ALREADY-SETTLED)
    (try! (transfer amount contract-owner user-id none))
    (map-set users { event-id: event-id, outcome-id: win-outcome-id, user-id: user-id }
      (merge user { is-settled: true })
    )
    (ok true)
  )
)
(define-public (pay-rewards (keys (list 200 { event-id: uint, user-id: principal })))
  (fold check-err (map pay-reward keys) (ok true))
)

(define-public (claim-refund (event-id uint) (outcome-id uint))
  (let
    (
      (event (unwrap! (get-event event-id) ERR-EVENT-NOT-FOUND))
      (status (get status event))
      (user (unwrap! (get-user event-id outcome-id tx-sender) ERR-USER-NOT-FOUND))
      (amount (get share-amount user))
      (is-settled (get is-settled user))
    )
    (asserts! (is-eq status u6) ERR-EVENT-NOT-CANCELED)
    (asserts! (> amount u0) ERR-INVALID-AMOUNT)
    (asserts! (is-eq is-settled false) ERR-ALREADY-SETTLED)
    (try! (transfer amount contract-owner tx-sender none))
    (map-set users { event-id: event-id, outcome-id: outcome-id, user-id: tx-sender }
      (merge user { is-settled: true })
    )
    (ok { fund: amount })
  )
)

(define-public (refund-fund (key { event-id: uint, outcome-id: uint, user-id: principal}))
  (let
    (
      (event-id (get event-id key))
      (outcome-id (get outcome-id key))
      (user-id (get user-id key))
      (event (unwrap! (get-event event-id) ERR-EVENT-NOT-FOUND))
      (status (get status event))
      (user (unwrap! (get-user event-id outcome-id user-id) ERR-USER-NOT-FOUND))
      (amount (get share-amount user))
      (is-settled (get is-settled user))
    )
    (asserts! (is-eq status u6) ERR-EVENT-NOT-CANCELED)
    (asserts! (> amount u0) ERR-INVALID-AMOUNT)
    (asserts! (is-eq is-settled false) ERR-ALREADY-SETTLED)
    (try! (transfer amount contract-owner user-id none))
    (map-set users { event-id: event-id, outcome-id: outcome-id, user-id: user-id }
      (merge user { is-settled: true })
    )
    (ok true)
  )
)
(define-public (refund-funds (keys (list 200 { event-id: uint, outcome-id: uint, user-id: principal })))
  (fold check-err (map refund-fund keys) (ok true))
)

;; ---------------------------------------------------------
;; LMSR
;; ---------------------------------------------------------

;; y = sum(e^(q_i / b))
(define-read-only (get-exp-qb (qqb { id: uint, q: uint, qb: uint }))
  (exp (get qb qqb))
)
(define-read-only (get-sum-exp (qqbs (list 10 { id: uint, q: uint, qb: uint })))
  (fold + (map get-exp-qb qqbs) u0)
)

;; C = b * ln(sum(e^(q_i / b)))
(define-read-only (get-cost (beta uint) (qqbs (list 10 { id: uint, q: uint, qb: uint })))
  (let
    (
      (sum-exp (get-sum-exp qqbs))
    )
    (/ (* beta (ln sum-exp)) SCALE)
  )
)

;; delta_C = C(new) - C(current)
(define-read-only (get-delta-cost (beta uint) (qqbs (list 10 { id: uint, q: uint, qb: uint })) (id uint) (is-buy bool) (amount uint))
  (let
    (
      (n-qqbs (get-new-qqbs beta qqbs id is-buy amount))
      (cost-before (get-cost beta qqbs))
      (cost-after (get-cost beta n-qqbs))
    )
    (if (< cost-after cost-before)
      (- cost-before cost-after)
      (- cost-after cost-before)
    )
  )
)

;; C_i = e^(q_i / b) / sum(e^(q / b))
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
  (contract-call? .augur-token get-balance user-id)
)

;; Get q and q/b for each event outcome
(define-read-only (is-some-outcome (outcome (optional { desc: (string-ascii 128), share-amount: uint })))
  (is-some outcome)
)
(define-read-only (unwrap-panic-outcome (outcome (optional { desc: (string-ascii 128), share-amount: uint })))
  (unwrap-panic outcome)
)
(define-read-only (get-qqb (id uint) (outcome { desc: (string-ascii 128), share-amount: uint }) (beta uint))
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
      (f-outcomes (filter is-some-outcome r-outcomes))
      (u-outcomes (map unwrap-panic-outcome f-outcomes))
    )
    (if (is-eq (len u-outcomes) u0)
      (list)
      (map get-qqb
        (list u0 u1 u2 u3 u4 u5 u6 u7 u8 u9)
        u-outcomes
        (list beta beta beta beta beta beta beta beta beta beta)
      )
    )
  )
)

;; Get new updated q and q/b based on the current ones
(define-read-only (get-new-qqb (qqb { id: uint, q: uint, qb: uint }))
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

(define-private (buy-shares (event-id uint) (outcome-id uint) (amount uint) (cost uint))
  (let
    (
      (outcome (unwrap! (get-outcome event-id outcome-id) ERR-OUTCOME-NOT-FOUND))
      (user (default-to
        { share-amount: u0, is-settled: false }
        (get-user event-id outcome-id tx-sender)
      ))
      (balance (unwrap! (get-balance tx-sender) ERR-BALANCE-NOT-FOUND))
    )
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

(define-private (sell-shares (event-id uint) (outcome-id uint) (amount uint) (cost uint))
  (let
    (
      (outcome (unwrap! (get-outcome event-id outcome-id) ERR-OUTCOME-NOT-FOUND))
      (user (unwrap! (get-user event-id outcome-id tx-sender) ERR-USER-NOT-FOUND))
    )
    (asserts! (<= amount (get share-amount user)) ERR-SHARES-TOO-LOW)
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

(define-private (insert-outcome (event-id uint) (outcome-id uint) (outcome { desc: (string-ascii 128), share-amount: uint }))
  (map-insert
    outcomes
    { event-id: event-id, outcome-id: outcome-id }
    {
      desc: (get desc outcome),
      share-amount: (get share-amount outcome)
    }
  )
)

(define-private (transfer (amount uint) (sender principal) (recipient principal) (memo (optional (buff 34))))
  (contract-call? .augur-token transfer amount sender recipient memo)
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

(define-read-only (get-exp-lower (x uint))
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
                                      u0)))))))))))))))))))

(define-read-only (get-exp-upper (x uint))
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
                                      u30000000)))))))))))))))))))

(define-read-only (exp (x uint))
  (let
    (
      (lower-x (get-exp-lower x))
      (upper-x (get-exp-upper x))
      (lower-val (get value (unwrap-panic (map-get? exp-lookup { x: lower-x }))))
      (upper-val (get value (unwrap-panic (map-get? exp-lookup { x: upper-x }))))
      (diff-x (- upper-x lower-x))
      (val (if (is-eq diff-x u0)
        u0
        (/ (* (- upper-val lower-val) (- x lower-x)) diff-x)
      ))
    )
    (+ lower-val val)
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
  (map-insert ln-lookup { x: u200000000000000 } { value: u19113827 }) ;; ln(200000000)
  (map-insert ln-lookup { x: u3000000000000000 } { value: u21821878 }) ;; ln(3x10^9)
  (map-insert ln-lookup { x: u40000000000000000 } { value: u24412145 }) ;; ln(4x10^10)
  (map-insert ln-lookup { x: u500000000000000000 } { value: u26937873 }) ;; ln(5x10^11)
)

(define-read-only (get-ln-lower (x uint))
  (if (>= x u500000000000000000) u500000000000000000
    (if (>= x u40000000000000000) u40000000000000000
      (if (>= x u3000000000000000) u3000000000000000
        (if (>= x u200000000000000) u200000000000000
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
                                          (if (>= x u3000000) u3000000
                                            (if (>= x u2000000) u2000000
                                              u1000000)))))))))))))))))))))))

(define-read-only (get-ln-upper (x uint))
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
                                      (if (<= x u10000000000000) u10000000000000
                                        (if (<= x u200000000000000) u200000000000000
                                          (if (<= x u3000000000000000) u3000000000000000
                                            (if (<= x u40000000000000000) u40000000000000000
                                              u500000000000000000)))))))))))))))))))))))

(define-read-only (ln (x uint))
  (let
    (
      (lower-x (get-ln-lower x))
      (upper-x (get-ln-upper x))
      (lower-val (get value (unwrap-panic (map-get? ln-lookup { x: lower-x }))))
      (upper-val (get value (unwrap-panic (map-get? ln-lookup { x: upper-x }))))
      (diff-x (- upper-x lower-x))
      (val (if (is-eq diff-x u0)
        u0
        (/ (* (- upper-val lower-val) (- x lower-x)) diff-x)
      ))
    )
    (+ lower-val val)
  )
)
