(define-constant ERR-ALREADY-ENROLLED (err u801))

(define-constant contract-owner tx-sender)
(define-constant bonus u1000000000)
(define-map users
  { user-id: principal }
  { enrolled: bool }
)

(define-public (enroll (recipient principal))
  (let
    (
      (user (default-to { enrolled: false } (get-user recipient)))
      (enrolled (get enrolled user))
    )
    (asserts! (is-eq enrolled false) ERR-ALREADY-ENROLLED)
    (try! (transfer bonus contract-owner recipient none))
    (map-set users { user-id: recipient }
      (merge user { enrolled: true })
    )
    (ok true)
  )
)

(define-read-only (get-user (user-id principal))
  (map-get? users { user-id: user-id })
)

(define-private (transfer (amount uint) (sender principal) (recipient principal) (memo (optional (buff 34))))
  (contract-call? .augur-token transfer amount sender recipient memo)
)
