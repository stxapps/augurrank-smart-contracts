;; title: augurrank-btc
;; version:
;; summary:
;; description:

(define-constant lead-time u100)
(define-constant pred-fee u100000)
(define-constant augurrank-addr 'ST1J4G6RR643BCG8G8SR6M2D9Z9KXT2NJDRK3FBTK)
(define-constant amm-contract 'SP102V8P0F7JX67ARQ77WEA3D3CFB5XW39REDT0AM.amm-pool-v2-01)
(define-constant token-btc 'SP102V8P0F7JX67ARQ77WEA3D3CFB5XW39REDT0AM.token-btc)
(define-constant token-usd 'SP102V8P0F7JX67ARQ77WEA3D3CFB5XW39REDT0AM.token-usd)

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

        (map-set last-heights contract-caller block-height)
        (map-set last-ids contract-caller id)
        (map-set preds
            { addr: contract-caller, id: id }
            { height: block-height, value: value }
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

        (asserts! (< target-height block-height) err-premature-verify)

        (let
            (
                (anchor-price (get-price anchor-height))
                (target-price (get-price target-height))
                (up-and-more
                    (and (is-eq value "up") (> target-btc-price anchor-btc-price))
                )
                (down-and-less
                    (and (is-eq value "down") (< target-btc-price anchor-btc-price))
                )
                (result
                    {
                        anchor-price: anchor-price,
                        target-price: target-price,
                        correct: (or up-and-more down-and-less)
                    }
                )
            )
            (map-set results { addr: addr, id: id } result)
            (ok result)
        )
    )
)

(define-private (get-price (height uint))
    (let
        (
            (id (unwrap! (get-stacks-block-info? id-header-hash height) err-invalid-args))
        )
        (at-block id
            (let
                (
                    (price (try!
                        (contract-call?
                            .amm-pool-v2-01 get-price token-x token-y 0
                        )
                    ))
                )
                (ok price)
            )
        )
    )
)