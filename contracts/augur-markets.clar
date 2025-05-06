(define-constant ERR-UNAUTHORIZED (err u801))

(define-constant ERR-EVENT-NOT-FOUND (err u811))
(define-constant ERR-OUTCOME-NOT-FOUND (err u812))
(define-constant ERR-USER-NOT-FOUND (err u813))
(define-constant ERR-BALANCE-NOT-FOUND (err u814))
(define-constant ERR-WIN-OUTCOME-NOT-FOUND (err u815))

(define-constant ERR-INVALID-WIN-OUTCOME-ID (err u821))
(define-constant ERR-INVALID-AMOUNT (err u822))

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
    (if (<= cost1 max-cost)
      (buy-shares event-id outcome-id amt1 cost1)
      (let
        (
          (cost2 (get-delta-cost beta qqbs outcome-id true amt2))
        )
        (asserts! (is-amount-valid amt2) ERR-INVALID-AMOUNT)
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
    (if (<= cost1 max-cost)
      (buy-shares event-id outcome-id amt1 cost1)
      (let
        (
          (cost2 (get-delta-cost beta qqbs outcome-id true amt2))
        )
        (asserts! (is-amount-valid amt2) ERR-INVALID-AMOUNT)
        (if (<= cost2 max-cost)
          (buy-shares event-id outcome-id amt2 cost2)
          (let
            (
              (cost3 (get-delta-cost beta qqbs outcome-id true amt3))
            )
            (asserts! (is-amount-valid amt3) ERR-INVALID-AMOUNT)
            (if (<= cost3 max-cost)
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
    (if (>= cost1 min-cost)
      (sell-shares event-id outcome-id amt1 cost1)
      (let
        (
          (cost2 (get-delta-cost beta qqbs outcome-id false amt2))
        )
        (asserts! (is-amount-valid amt2) ERR-INVALID-AMOUNT)
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
    (if (>= cost1 min-cost)
      (sell-shares event-id outcome-id amt1 cost1)
      (let
        (
          (cost2 (get-delta-cost beta qqbs outcome-id false amt2))
        )
        (asserts! (is-amount-valid amt2) ERR-INVALID-AMOUNT)
        (if (>= cost2 min-cost)
          (sell-shares event-id outcome-id amt2 cost2)
          (let
            (
              (cost3 (get-delta-cost beta qqbs outcome-id false amt3))
            )
            (asserts! (is-amount-valid amt3) ERR-INVALID-AMOUNT)
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
      (delta-cost (if (< cost-after cost-before)
        (- cost-before cost-after)
        (- cost-after cost-before)
      ))
    )
    (if (> delta-cost amount) amount delta-cost)
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

;; Get outcome share amounts
(define-read-only (get-share-amount (outcome { desc: (string-ascii 128), share-amount: uint }))
  (get share-amount outcome)
)
(define-read-only (get-share-amounts (event-id uint))
  (let
    (
      (r-outcomes (map
        get-outcome
        (list event-id event-id event-id event-id event-id event-id event-id event-id event-id event-id)
        (list u0 u1 u2 u3 u4 u5 u6 u7 u8 u9)
      ))
      (f-outcomes (filter is-some-outcome r-outcomes))
      (u-outcomes (map unwrap-panic-outcome f-outcomes))
      (amounts (map get-share-amount u-outcomes))
    )
    { amounts: amounts }
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
    (ok { amount: amount, cost: cost })
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
    (ok { amount: amount, cost: cost })
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
  (map-insert exp-lookup { x: u0 } { value: u1000000 })
  (map-insert exp-lookup { x: u500000 } { value: u1648721 })
  (map-insert exp-lookup { x: u1000000 } { value: u2718281 })
  (map-insert exp-lookup { x: u1500000 } { value: u4481689 })
  (map-insert exp-lookup { x: u2000000 } { value: u7389056 })
  (map-insert exp-lookup { x: u2500000 } { value: u12182493 })
  (map-insert exp-lookup { x: u3000000 } { value: u20085536 })
  (map-insert exp-lookup { x: u3500000 } { value: u33115451 })
  (map-insert exp-lookup { x: u4000000 } { value: u54598150 })
  (map-insert exp-lookup { x: u4500000 } { value: u90017131 })
  (map-insert exp-lookup { x: u5000000 } { value: u148413159 })
  (map-insert exp-lookup { x: u6000000 } { value: u403428793 })
  (map-insert exp-lookup { x: u7000000 } { value: u1096633158 })
  (map-insert exp-lookup { x: u8000000 } { value: u2980957987 })
  (map-insert exp-lookup { x: u9000000 } { value: u8103083927 })
  (map-insert exp-lookup { x: u10000000 } { value: u22026465794 })
  (map-insert exp-lookup { x: u11000000 } { value: u59874141715 })
  (map-insert exp-lookup { x: u12000000 } { value: u162754791419 })
  (map-insert exp-lookup { x: u13000000 } { value: u442413392008 })
  (map-insert exp-lookup { x: u14000000 } { value: u1202604284164 })
  (map-insert exp-lookup { x: u15000000 } { value: u3269017372472 })
  (map-insert exp-lookup { x: u16000000 } { value: u8886110520507 })
  (map-insert exp-lookup { x: u17000000 } { value: u24154952753575 })
  (map-insert exp-lookup { x: u18000000 } { value: u65659969137330 })
  (map-insert exp-lookup { x: u19000000 } { value: u178482300963187 })
  (map-insert exp-lookup { x: u20000000 } { value: u485165195409790 })
  (map-insert exp-lookup { x: u21000000 } { value: u1318815734483214 })
  (map-insert exp-lookup { x: u22000000 } { value: u3584912846131592 })
  (map-insert exp-lookup { x: u23000000 } { value: u9744803446248903 })
  (map-insert exp-lookup { x: u24000000 } { value: u26489122129843470 })
  (map-insert exp-lookup { x: u25000000 } { value: u72004899337385880 })
  (map-insert exp-lookup { x: u25500000 } { value: u118716009132169650 })
  (map-insert exp-lookup { x: u26000000 } { value: u195729609428838780 })
  (map-insert exp-lookup { x: u26500000 } { value: u322703570371154850 })
  (map-insert exp-lookup { x: u27000000 } { value: u532048240601798650 })
  (map-insert exp-lookup { x: u27500000 } { value: u877199251318764900 })
  (map-insert exp-lookup { x: u28000000 } { value: u1446257064291475000 })
  (map-insert exp-lookup { x: u28500000 } { value: u2384474784797677700 })
  (map-insert exp-lookup { x: u29000000 } { value: u3931334297144042000 })
  (map-insert exp-lookup { x: u29500000 } { value: u6481674477934320000 })
  (map-insert exp-lookup { x: u30000000 } { value: u10686474581524463000 })
)

(define-read-only (get-exp-lower (x uint))
  (if (>= x u30000000) u30000000
    (if (>= x u29500000) u29500000
      (if (>= x u29000000) u29000000
        (if (>= x u28500000) u28500000
          (if (>= x u28000000) u28000000
            (if (>= x u27500000) u27500000
              (if (>= x u27000000) u27000000
                (if (>= x u26500000) u26500000
                  (if (>= x u26000000) u26000000
                    (if (>= x u25500000) u25500000
                      (if (>= x u25000000) u25000000
                        (if (>= x u24000000) u24000000
                          (if (>= x u23000000) u23000000
                            (if (>= x u22000000) u22000000
                              (if (>= x u21000000) u21000000
                                (if (>= x u20000000) u20000000
                                  (if (>= x u19000000) u19000000
                                    (if (>= x u18000000) u18000000
                                      (if (>= x u17000000) u17000000
                                        (if (>= x u16000000) u16000000
                                          (get-exp-lower-lower x))))))))))))))))))))))

(define-read-only (get-exp-lower-lower (x uint))
  (if (>= x u15000000) u15000000
    (if (>= x u14000000) u14000000
      (if (>= x u13000000) u13000000
        (if (>= x u12000000) u12000000
          (if (>= x u11000000) u11000000
            (if (>= x u10000000) u10000000
              (if (>= x u9000000) u9000000
                (if (>= x u8000000) u8000000
                  (if (>= x u7000000) u7000000
                    (if (>= x u6000000) u6000000
                      (if (>= x u5000000) u5000000
                        (if (>= x u4500000) u4500000
                          (if (>= x u4000000) u4000000
                            (if (>= x u3500000) u3500000
                              (if (>= x u3000000) u3000000
                                (if (>= x u2500000) u2500000
                                  (if (>= x u2000000) u2000000
                                    (if (>= x u1500000) u1500000
                                      (if (>= x u1000000) u1000000
                                        (if (>= x u500000) u500000
                                          u0)))))))))))))))))))))

(define-read-only (get-exp-upper (x uint))
  (if (<= x u0) u0
    (if (<= x u500000) u500000
      (if (<= x u1000000) u1000000
        (if (<= x u1500000) u1500000
          (if (<= x u2000000) u2000000
            (if (<= x u2500000) u2500000
              (if (<= x u3000000) u3000000
                (if (<= x u3500000) u3500000
                  (if (<= x u4000000) u4000000
                    (if (<= x u4500000) u4500000
                      (if (<= x u5000000) u5000000
                        (if (<= x u6000000) u6000000
                          (if (<= x u7000000) u7000000
                            (if (<= x u8000000) u8000000
                              (if (<= x u9000000) u9000000
                                (if (<= x u10000000) u10000000
                                  (if (<= x u11000000) u11000000
                                    (if (<= x u12000000) u12000000
                                      (if (<= x u13000000) u13000000
                                        (if (<= x u14000000) u14000000
                                          (get-exp-upper-upper x))))))))))))))))))))))

(define-read-only (get-exp-upper-upper (x uint))
  (if (<= x u15000000) u15000000
    (if (<= x u16000000) u16000000
      (if (<= x u17000000) u17000000
        (if (<= x u18000000) u18000000
          (if (<= x u19000000) u19000000
            (if (<= x u20000000) u20000000
              (if (<= x u21000000) u21000000
                (if (<= x u22000000) u22000000
                  (if (<= x u23000000) u23000000
                    (if (<= x u24000000) u24000000
                      (if (<= x u25000000) u25000000
                        (if (<= x u25500000) u25500000
                          (if (<= x u26000000) u26000000
                            (if (<= x u26500000) u26500000
                              (if (<= x u27000000) u27000000
                                (if (<= x u27500000) u27500000
                                  (if (<= x u28000000) u28000000
                                    (if (<= x u28500000) u28500000
                                      (if (<= x u29000000) u29000000
                                        (if (<= x u29500000) u29500000
                                          u30000000)))))))))))))))))))))

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
  (map-insert ln-lookup { x: u1000000 } { value: u0 })
  (map-insert ln-lookup { x: u1612800 } { value: u477971 })
  (map-insert ln-lookup { x: u2532000 } { value: u929009 })
  (map-insert ln-lookup { x: u4083200 } { value: u1406880 })
  (map-insert ln-lookup { x: u6410000 } { value: u1857859 })
  (map-insert ln-lookup { x: u10334000 } { value: u2335439 })
  (map-insert ln-lookup { x: u16220000 } { value: u2786245 })
  (map-insert ln-lookup { x: u26159616 } { value: u3264216 })
  (map-insert ln-lookup { x: u41069040 } { value: u3715254 })
  (map-insert ln-lookup { x: u66236147 } { value: u4193226 })
  (map-insert ln-lookup { x: u103986809 } { value: u4644264 })
  (map-insert ln-lookup { x: u263294601 } { value: u5573273 })
  (map-insert ln-lookup { x: u666661929 } { value: u6502283 })
  (map-insert ln-lookup { x: u1687988006 } { value: u7431292 })
  (map-insert ln-lookup { x: u4273985632 } { value: u8360302 })
  (map-insert ln-lookup { x: u10821731622 } { value: u9289311 })
  (map-insert ln-lookup { x: u27400624468 } { value: u10218321 })
  (map-insert ln-lookup { x: u69378381154 } { value: u11147330 })
  (map-insert ln-lookup { x: u175803743074 } { value: u12077123 })
  (map-insert ln-lookup { x: u445135077462 } { value: u13006133 })
  (map-insert ln-lookup { x: u1127082016130 } { value: u13935142 })
  (map-insert ln-lookup { x: u2853771664850 } { value: u14864152 })
  (map-insert ln-lookup { x: u7225749855410 } { value: u15793161 })
  (map-insert ln-lookup { x: u18295598633900 } { value: u16722171 })
  (map-insert ln-lookup { x: u46324455741000 } { value: u17651180 })
  (map-insert ln-lookup { x: u117293521936000 } { value: u18580190 })
  (map-insert ln-lookup { x: u296987197543000 } { value: u19509199 })
  (map-insert ln-lookup { x: u751971584178000 } { value: u20438209 })
  (map-insert ln-lookup { x: u1903992051140000 } { value: u21367218 })
  (map-insert ln-lookup { x: u4820907873480000 } { value: u22296228 })
  (map-insert ln-lookup { x: u12206538735700000 } { value: u23225237 })
  (map-insert ln-lookup { x: u30906956078700000 } { value: u24154247 })
  (map-insert ln-lookup { x: u78256412791200000 } { value: u25083256 })
  (map-insert ln-lookup { x: u198145237187000000 } { value: u26012266 })
  (map-insert ln-lookup { x: u501703740558000000 } { value: u26941275 })
)

(define-read-only (get-ln-lower (x uint))
  (if (>= x u501703740558000000) u501703740558000000
    (if (>= x u198145237187000000) u198145237187000000
      (if (>= x u78256412791200000) u78256412791200000
        (if (>= x u30906956078700000) u30906956078700000
          (if (>= x u12206538735700000) u12206538735700000
            (if (>= x u4820907873480000) u4820907873480000
              (if (>= x u1903992051140000) u1903992051140000
                (if (>= x u751971584178000) u751971584178000
                  (if (>= x u296987197543000) u296987197543000
                    (if (>= x u117293521936000) u117293521936000
                      (if (>= x u46324455741000) u46324455741000
                        (if (>= x u18295598633900) u18295598633900
                          (if (>= x u7225749855410) u7225749855410
                            (if (>= x u2853771664850) u2853771664850
                              (if (>= x u1127082016130) u1127082016130
                                (if (>= x u445135077462) u445135077462
                                  (if (>= x u175803743074) u175803743074
                                    (if (>= x u69378381154) u69378381154
                                      (if (>= x u27400624468) u27400624468
                                        (if (>= x u10821731622) u10821731622
                                          (if (>= x u4273985632) u4273985632
                                            (if (>= x u1687988006) u1687988006
                                              (if (>= x u666661929) u666661929
                                                (if (>= x u263294601) u263294601
                                                  (if (>= x u103986809) u103986809
                                                    (if (>= x u66236147) u66236147
                                                      (if (>= x u41069040) u41069040
                                                        (if (>= x u26159616) u26159616
                                                          (if (>= x u16220000) u16220000
                                                            (if (>= x u10334000) u10334000
                                                              (if (>= x u6410000) u6410000
                                                                (if (>= x u4083200) u4083200
                                                                  (if (>= x u2532000) u2532000
                                                                    (if (>= x u1612800) u1612800
                                                                      u1000000)))))))))))))))))))))))))))))))))))

(define-read-only (get-ln-upper (x uint))
  (if (<= x u1000000) u1000000
    (if (<= x u1612800) u1612800
      (if (<= x u2532000) u2532000
        (if (<= x u4083200) u4083200
          (if (<= x u6410000) u6410000
            (if (<= x u10334000) u10334000
              (if (<= x u16220000) u16220000
                (if (<= x u26159616) u26159616
                  (if (<= x u41069040) u41069040
                    (if (<= x u66236147) u66236147
                      (if (<= x u103986809) u103986809
                        (if (<= x u263294601) u263294601
                          (if (<= x u666661929) u666661929
                            (if (<= x u1687988006) u1687988006
                              (if (<= x u4273985632) u4273985632
                                (if (<= x u10821731622) u10821731622
                                  (if (<= x u27400624468) u27400624468
                                    (if (<= x u69378381154) u69378381154
                                      (if (<= x u175803743074) u175803743074
                                        (if (<= x u445135077462) u445135077462
                                          (if (<= x u1127082016130) u1127082016130
                                            (if (<= x u2853771664850) u2853771664850
                                              (if (<= x u7225749855410) u7225749855410
                                                (if (<= x u18295598633900) u18295598633900
                                                  (if (<= x u46324455741000) u46324455741000
                                                    (if (<= x u117293521936000) u117293521936000
                                                      (if (<= x u296987197543000) u296987197543000
                                                        (if (<= x u751971584178000) u751971584178000
                                                          (if (<= x u1903992051140000) u1903992051140000
                                                            (if (<= x u4820907873480000) u4820907873480000
                                                              (if (<= x u12206538735700000) u12206538735700000
                                                                (if (<= x u30906956078700000) u30906956078700000
                                                                  (if (<= x u78256412791200000) u78256412791200000
                                                                    (if (<= x u198145237187000000) u198145237187000000
                                                                      u501703740558000000)))))))))))))))))))))))))))))))))))

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
