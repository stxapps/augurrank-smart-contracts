(impl-trait 'SP3FBR2AGK5H9QBDH3EEN6DF8EK8JY7RX8QJ5SVTE.sip-010-trait-ft-standard.sip-010-trait)

(define-fungible-token augur-token)

(define-constant ERR-UNAUTHORIZED (err u100))
(define-constant ERR-ONLY-MARKETS (err u101))

(define-constant contract-owner tx-sender)
(define-data-var markets-contract principal tx-sender)
(define-data-var store-contract principal tx-sender)
(define-data-var token-uri (optional (string-utf8 256)) none)

(define-public (transfer (amount uint) (sender principal) (recipient principal) (memo (optional (buff 34))))
  (begin
    (asserts!
      (or
        (and (is-eq tx-sender sender) (is-eq tx-sender contract-owner))
        (is-eq contract-caller (var-get markets-contract))
        (is-eq contract-caller (var-get store-contract))
      )
      ERR-ONLY-MARKETS
    )
    (try! (ft-transfer? augur-token amount sender recipient))
    (match memo to-print (print to-print) 0x)
    (ok true)
  )
)

(define-read-only (get-name)
  (ok "Augur")
)

(define-read-only (get-symbol)
  (ok "AUG")
)

(define-read-only (get-decimals)
  (ok u6)
)

(define-read-only (get-balance (owner principal))
  (ok (ft-get-balance augur-token owner))
)

(define-read-only (get-total-supply)
  (ok (ft-get-supply augur-token))
)

(define-read-only (get-token-uri)
  (ok (var-get token-uri))
)

(define-public (set-markets-contract (new-contract principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) ERR-UNAUTHORIZED)
    (var-set markets-contract new-contract)
    (ok true)
  )
)

(define-public (set-store-contract (new-contract principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) ERR-UNAUTHORIZED)
    (var-set store-contract new-contract)
    (ok true)
  )
)

(define-public (set-token-uri (value (string-utf8 256)))
  (begin
    (asserts! (is-eq tx-sender contract-owner) ERR-UNAUTHORIZED)
    (var-set token-uri (some value))
    (ok (print {
      notification: "token-metadata-update",
      payload: {
        contract-id: (as-contract tx-sender),
        token-class: "ft"
      }
    }))
  )
)

(define-public (mint (amount uint) (recipient principal) (memo (optional (buff 34))))
  (begin
    (asserts! (is-eq tx-sender contract-owner) ERR-UNAUTHORIZED)
    (try! (ft-mint? augur-token amount recipient))
    (match memo to-print (print to-print) 0x)
    (ok true)
  )
)

(define-public (burn (amount uint))
  (ft-burn? augur-token amount tx-sender)
)

;; ---------------------------------------------------------
;; Utility
;; ---------------------------------------------------------

(define-public (send-many (recipients (list 200 { to: principal, amount: uint, memo: (optional (buff 34)) })))
  (fold check-err (map send-token recipients) (ok true))
)

(define-private (check-err (result (response bool uint)) (prior (response bool uint)))
  (match prior ok-value result err-value (err err-value))
)

(define-private (send-token (recipient { to: principal, amount: uint, memo: (optional (buff 34)) }))
  (send-token-with-memo (get amount recipient) (get to recipient) (get memo recipient))
)

(define-private (send-token-with-memo (amount uint) (to principal) (memo (optional (buff 34))))
  (let ((transferOk (try! (transfer amount tx-sender to memo))))
    (ok transferOk)
  )
)
