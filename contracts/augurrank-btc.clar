;; title: augurrank-btc
;; version:
;; summary:
;; description:

(define-constant lead-height u2048)
(define-constant pred-fee u100000)

(define-constant err-invalid-args (err u100))
(define-constant err-in-anticipation (err u101))
(define-constant err-premature-verify (err u102))
(define-constant err-contract-call (err u103))

(define-constant contract-deployer tx-sender)

(define-map last-ids principal uint)
(define-map preds
    { addr: principal, id: uint }
    { height: uint, value: (string-ascii 4) }
)

(define-public (predict (value (string-ascii 4)))
    (begin
        (asserts! (or (is-eq value "up") (is-eq value "down")) err-invalid-args)

        (let
            (
                (last-id (default-to u0 (map-get? last-ids contract-caller)))
                (last-pred (default-to { height: u0, value: "" } (map-get? preds { addr: contract-caller, id: last-id })))
                (id (+ last-id u1))
                (last-height (get height last-pred))
            )

            (asserts! (< last-height (- stacks-block-height lead-height)) err-in-anticipation)

            (map-set last-ids contract-caller id)
            (map-set preds
                { addr: contract-caller, id: id }
                { height: stacks-block-height, value: value }
            )

            (stx-transfer? pred-fee contract-caller contract-deployer)
        )
    )
)

(define-read-only (verify (addr principal) (id uint))
    (let
        (
            (pred (unwrap! (map-get? preds { addr: addr, id: id }) err-invalid-args))
            (anchor-height (get height pred))
            (target-height (+ anchor-height lead-height))
        )
        (asserts! (< target-height stacks-block-height) err-premature-verify)

        (let
            (
                (anchor-price (try! (get-price anchor-height)))
                (target-price (try! (get-price target-height)))
                (value (get value pred))
                (up-and-more
                    (and (is-eq value "up") (> target-price anchor-price))
                )
                (down-and-less
                    (and (is-eq value "down") (< target-price anchor-price))
                )
            )
            (ok {
                anchor-height: anchor-height,
                target-height: target-height,
                anchor-price: anchor-price,
                target-price: target-price,
                value: value,
                correct: (or up-and-more down-and-less)
            })
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
                    (price (unwrap!
                        (contract-call?
                            .amm-pool-v2-01
                            get-price
                            'SP102V8P0F7JX67ARQ77WEA3D3CFB5XW39REDT0AM.token-btc
                            'SP102V8P0F7JX67ARQ77WEA3D3CFB5XW39REDT0AM.token-usd
                            u0
                        )
                        err-contract-call
                    ))
                )
                (ok price)
            )
        )
    )
)
