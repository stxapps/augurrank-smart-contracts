
(define-constant ERR-UNAUTHORIZED (err u200))

(define-constant ERR-EVENT-NOT-FOUND (err u202))
(define-constant ERR-OUTCOME-NOT-FOUND (err u203))

(define-constant ERR-EVENT-NOT-OPENED (err u205))
(define-constant ERR-EVENT-NOT-RESOLVED (err u205))

(define-constant ERR-INVALID-AMOUNT (err u201))
(define-constant ERR-INVALID-COST (err u201))

ERR-COST-TOO-HIGH
ERR-BALANCE-TOO-LOW
ERR-AMOUNT-TOO-LOW


(define-constant SCALE u1000000)
(define-constant E u2718281) ;; e ≈ 2.718281

(define-constant contract-owner principal tx-sender)
(define-data-var token-contract principal tx-sender) ;; TODO must set new value?
(define-data-var next-event-id uint u0)

(define-map events
  { event-id: uint }
  {
    title: (string-ascii 256),
    description: (string-ascii 256),
    status: uint,
    beta: uint ;; LMSR sensitivity parameter (in micro-units, e.g., u1000000 = 1.0)
  }
)
(define-map outcomes
  { event-id: uint, outcome-id: uint }
  { 
    description: (string-ascii 128),
    share-amount: uint, ;; Total shares issued (in micro-units)
    ;;winning: (optional bool) ;; Set after resolution
  }
)
(define-map users
  { event-id: uint, outcome-id: uint, user: principal }
  { share-amount: uint } ;; (in micro-units)
)

;; Create an event (admin only)
(define-public (create-event (description (string-ascii 256)) (beta uint) (outcome-descs (list 10 (string-ascii 128))))
  (let
    (
      (event-id (var-get next-event-id))
    )
    (asserts! (is-eq tx-sender (var-get admin)) ERR-UNAUTHORIZED)
    (map-insert
       events
       { event-id: event-id }
       { description: description, resolved: false, resolution-time: none, beta: beta }
    )
    (map set-outcome outcome-descs event-id)
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
      { description: desc, total-shares: u0, winning: none }
    )
  )
)




;;
;; should always fix to 10 choices/outcomes? should specify when create an event?
;;





;; Buy shares
(define-public (sell-shares (event-id uint) (outcome-id uint) (amount uint))
  (let
    (
      (event (unwrap-panic (map-get? events { event-id: event-id })))
      (beta (get beta event))
      (shares (get-outcome-shares event-id))
      (cost (get-delta-cost beta shares outcome-id true amount))
      (outcome (unwrap-panic (map-get? outcomes { event-id: event-id, outcome-id: outcome-id })))
      (user (default-to
        { share-amount: u0 }
        (map-get? users { event-id: event-id, outcome-id: outcome-id, user: tx-sender })
      ))
      (balance (unwrap-panic (contract-call? (var-get token-contract) get-balance tx-sender)))
    )
    (asserts! (is-eq (get status event) 1) ERR-EVENT-NOT-OPENED)
    (asserts! (> amount u0) ERR-INVALID-AMOUNT)
    ;; amount in whole shares, no frac
    (asserts! (> cost u0) ERR-INVALID-COST)
    (asserts! (<= cost balance) ERR-BALANCE-TOO-LOW)
    (try!
      (contract-call? (var-get token-contract) transfer cost tx-sender contract-owner none)
    )
    (map-set outcomes { event-id: event-id, outcome-id: outcome-id }
      (merge outcome { share-amount: (+ (get share-amount outcome) amount) })
    )
    (map-set users { event-id: event-id, outcome-id: outcome-id, user: tx-sender }
      (merge user { share-amount: (+ (get share-amount user) amount) })
    )
    (ok { cost: cost })
  )
)

(define-public (buy-shares (event-id uint) (outcome-id uint) (max-cost uint))
  (let
    (
      (event (unwrap-panic (map-get? events { event-id: event-id })))
      (beta (get beta event))
      (shares (get-outcome-shares event-id))
      (amount (get-delta-amount beta shares outcome-id max-cost))
      (cost (get-delta-cost beta shares outcome-id true amount))
      (outcome (unwrap-panic (map-get? outcomes { event-id: event-id, outcome-id: outcome-id })))
      (user (default-to
        { share-amount: u0 }
        (map-get? users { event-id: event-id, outcome-id: outcome-id, user: tx-sender })
      ))
      (balance (unwrap-panic (contract-call? (var-get token-contract) get-balance tx-sender)))
    )
    (asserts! (is-eq (get status event) 1) ERR-EVENT-NOT-OPENED)
    (asserts! (> amount u0) ERR-INVALID-AMOUNT)
    (asserts! (> cost u0) ERR-INVALID-COST)
    (asserts! (<= cost max-cost) ERR-COST-TOO-HIGH)
    (asserts! (<= cost balance) ERR-BALANCE-TOO-LOW)
    (try!
      (contract-call? (var-get token-contract) transfer cost tx-sender contract-owner none)
    )
    (map-set outcomes { event-id: event-id, outcome-id: outcome-id }
      (merge outcome { share-amount: (+ (get share-amount outcome) amount) })
    )
    (map-set users { event-id: event-id, outcome-id: outcome-id, user: tx-sender }
      (merge user { share-amount: (+ (get share-amount user) amount) })
    )
    (ok {
      amount: amount,
      cost: cost
    })
  )
)

(define-public (sell-shares (event-id uint) (outcome-id uint) (amount uint))
  (let
    (
      (event (unwrap-panic (map-get? events { event-id: event-id })))
      (beta (get beta event))
      (shares (get-outcome-shares event-id))
      (cost (get-delta-cost beta shares outcome-id false amount))
      (outcome (unwrap-panic (map-get? outcomes { event-id: event-id, outcome-id: outcome-id })))
      (user (unwrap-panic (map-get? users { event-id: event-id, outcome-id: outcome-id, user: tx-sender })))
    )
    (asserts! (is-eq (get status event) 1) ERR-EVENT-NOT-OPENED)
    (asserts! (> amount u0) ERR-INVALID-AMOUNT)    
    ;; amount in whole shares, no frac
    (asserts! (> cost u0) ERR-INVALID-COST)
    (asserts! (<= amount (get share-amount user)) ERR-AMOUNT-TOO-LOW)
    (try!
      (contract-call? (var-get token-contract) transfer cost contract-owner tx-sender none)
    )
    (map-set outcomes { event-id: event-id, outcome-id: outcome-id }
      (merge outcome { share-amount: (- (get share-amount outcome) amount) })
    )
    (map-set users { event-id: event-id, outcome-id: outcome-id, user: tx-sender }
      (merge user { share-amount: (- (get share-amount user) amount) })
    )
    (ok { cost: cost })
  )
)

;; buy and sell shares return current prices to keep up to date


;; Get current share prices per outcome for an event


;; set status


;; rewards



;; ---------------------------------------------------------
;; LMSR
;; ---------------------------------------------------------

;; y = ∑e^(q_i / b)
(define-private (get-sum-exp-inner (acc uint) (data { id: uint, amount: uint }))
  (+ acc (exp (/ (* (get amount data) SCALE) beta)))
)
(define-private (get-sum-exp (beta uint) (shares (list 10 { id: uint, amount: uint })))
  (fold get-sum-exp-inner shares u0)
)

;; C = b * ln(∑e^(q_i / b))
(define-private (get-cost (beta uint) (shares (list 10 { id: uint, amount: uint })))
  (let
    (
      (sum-exp (get-sum-exp beta shares))
    )
    (/ (* beta (ln sum-exp)) SCALE)
  )
)

;; ΔC = C(new) - C(current)
(define-private (get-delta-cost (beta uint) (shares (list 10 { id: uint, amount: uint })) (id uint) (is-buy bool) (amount uint))
  (let
    (
      (new-shares (get-new-shares shares id is-buy amount))
      (cost-before (get-cost beta shares))
      (cost-after (get-cost beta new-shares))
    )
    (if (<= cost-after cost-before)
      u0
      (- cost-after cost-before)
    )
  )
)

;; Δq = b * ln(S * e^(C / b) - S + e^(q_k / b)) - q_k, S = ∑e^(q_i / b)
(define-private (get-delta-amount (beta uint) (shares (list 10 { id: uint, amount: uint })) (id uint) (max-cost uint))
  (let
    (
      (sum-exp (get-sum-exp shares))
      (qk (get amount (unwrap-panic (element-at? shares id))))
      (exp-qkb (exp (/ (* qk SCALE) beta)))
      (exp-cb (exp (/ (* max-cost SCALE) beta)))
      (inner-term (- (+ (/ (* sum-exp exp-cb) SCALE) exp-qkb) sum-exp))
    )
    (if (< inner-term u1) 
      u0
      (let
        (
          (ln-term (ln inner-term))
          (new-qk (/ (* beta ln-term) SCALE))
        )
        (if (<= new-qk qk)
          u0
          (* (/ (- new-qk current-qk) SCALE) SCALE) ;; whole shares, no frac
        )
      )
    )
  )
)

;; ---------------------------------------------------------
;; Helpers
;; ---------------------------------------------------------

;; Get share amounts per outcome for an event
(define-private (get-outcome-shares (event-id uint))
  (let
    (
      (outcome-0 (map-get? outcomes { event-id: event-id, outcome-id: u0 }))
      (outcome-1 (map-get? outcomes { event-id: event-id, outcome-id: u1 }))
      (outcome-2 (map-get? outcomes { event-id: event-id, outcome-id: u2 }))
      (outcome-3 (map-get? outcomes { event-id: event-id, outcome-id: u3 }))
      (outcome-4 (map-get? outcomes { event-id: event-id, outcome-id: u4 }))
      (outcome-5 (map-get? outcomes { event-id: event-id, outcome-id: u5 }))
      (outcome-6 (map-get? outcomes { event-id: event-id, outcome-id: u6 }))
      (outcome-7 (map-get? outcomes { event-id: event-id, outcome-id: u7 }))
      (outcome-8 (map-get? outcomes { event-id: event-id, outcome-id: u8 }))
      (outcome-9 (map-get? outcomes { event-id: event-id, outcome-id: u9 }))
      (wrpd-shares (filter
        is-some
        (list
          (match outcome-0 data (some { id: u0, amount: (get share-amount data) }) none)
          (match outcome-1 data (some { id: u1, amount: (get share-amount data) }) none)
          (match outcome-2 data (some { id: u2, amount: (get share-amount data) }) none)
          (match outcome-3 data (some { id: u3, amount: (get share-amount data) }) none)
          (match outcome-4 data (some { id: u4, amount: (get share-amount data) }) none)
          (match outcome-5 data (some { id: u5, amount: (get share-amount data) }) none)
          (match outcome-6 data (some { id: u6, amount: (get share-amount data) }) none)
          (match outcome-7 data (some { id: u7, amount: (get share-amount data) }) none)
          (match outcome-8 data (some { id: u8, amount: (get share-amount data) }) none)
          (match outcome-9 data (some { id: u9, amount: (get share-amount data) }) none)
        )
      ))
    )
    (
      (map unwrap-panic wrpd-shares)
    )
  )
)

;; Get new updated shares based on the current ones
(define-private (get-new-share (share { id: uint, amount: uint }) (id uint) (is-buy bool) (amount uint))
  (if (is-eq (get id share) id)
    { 
      id: (get id share),
      amount: (if is-buy 
        (+ (get amount share) amount)
        (if (>= (get amount share) amount)
          (- (get amount share) amount)
          u0
        )
      )
    }
    share
  )
)
(define-private (get-new-shares (shares (list 10 { id: uint, amount: uint })) (id uint) (is-buy bool) (amount uint))
  (map
    get-new-share
    shares
    (list id id id id id id id id id id)
    (list is-buy is-buy is-buy is-buy is-buy is-buy is-buy is-buy is-buy is-buy)
    (list amount amount amount amount amount amount amount amount amount amount)
  )
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

(define-private (exp (x uint))
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

(define-private (ln (x uint))
  (let ((lower-x (get-ln-lower x))
        (upper-x (get-ln-upper x))
        (lower-val (get value (unwrap-panic (map-get? ln-lookup { x: lower-x }))))
        (upper-val (get value (unwrap-panic (map-get? ln-lookup { x: upper-x })))))
    (+ floor-val (/ (* (- upper-val lower-val) (- x lower-x)) (- upper-x lower-x)))
  )
)
