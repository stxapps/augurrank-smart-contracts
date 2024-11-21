;; title: augurrank-btc-price
;; version:
;; summary:
;; description:

(define-constant lead-time u100)
(define-constant pred-fee u100000)
(define-constant augurrank-addr 'ST1J4G6RR643BCG8G8SR6M2D9Z9KXT2NJDRK3FBTK)
(define-constant amm-contract 'xxx.amm-v2-0-1)

(define-constant err-invalid-args (err u100))
(define-constant err-in-anticipation (err u101))
(define-constant err-premature-verify (err u102))

(define-map last-heights principal uint)
(define-map last-ids principal uint)
(define-map preds
    { addr: principal, id: uint }
    { height: uint, value: (string-ascii 4) }
)
(define-map results
    { addr: principal, id: uint }
    { anchor-price: uint, target-price: uint, correct: bool }
)

(define-public (predict (value (string-ascii 4)))
    (let
        (
            (last-height (default-to u0 (map-get? last-heights contract-caller)))
            (last-id (default-to u0 (map-get? last-ids contract-caller)))
            (id (+ last-id u1))
        )

        (asserts! (or (is-eq value "up") (is-eq value "down")) err-invalid-args)
        (asserts! (< last-height (- burn-block-height lead-time)) err-in-anticipation)

        (map-set last-heights contract-caller burn-block-height)
        (map-set last-ids contract-caller id)
        (map-set preds
            { addr: contract-caller, id: id}
            { height: burn-block-height, value: value }
        )

        (ok (stx-transfer? pred-fee contract-caller augurrank-addr))
    )
)

(define-public (verify (addr principal) (id uint))
    (let
        (
            (pred (unwrap! (map-get? preds { addr: addr, id: id }) err-invalid-args))
            (anchor-height (get height pred))
            (target-height (+ anchor-height lead-time))
            (value (get value pred))
        )

        (asserts! (< target-height burn-block-height) err-premature-verify)

        (let
            (
                (anchor-btc-price (try!
                    (contract-call? .btc-price get-price anchor-height)
                ))
                (target-btc-price (try!
                    (contract-call? .btc-price get-price target-height)
                ))
                (up-and-more
                    (and (is-eq value "up") (> target-btc-price anchor-btc-price))
                )
                (down-and-less
                    (and (is-eq value "down") (< target-btc-price anchor-btc-price))
                )
            )
            (map-set results
                { addr: addr, id: id } { correct: (or up-and-more down-and-less) }
            )
            (ok true)
        )
    )
)

(define-public
    (verify-bulk (anchor-height uint) (keys (list 100 { addr: principal, id: uint })))
    (let
        (
            (target-height (+ anchor-height lead-time))
        )

        (asserts! (< target-height burn-block-height) err-premature-verify)

        ;; call a contract to get btc price at block anchor height
        ;; call a contract to get btc price at block target height
        ;; map 

        (ok true)
    )
)

(define-read-only (get-pred (addr principal) (id uint))
    (map-get? preds { addr: addr, id: id })
)

(define-read-only (get-result (addr principal) (id uint))
    (map-get? results { addr: addr, id: id })
)

(define-private (get-price (height uint))
    (at-block)
)
