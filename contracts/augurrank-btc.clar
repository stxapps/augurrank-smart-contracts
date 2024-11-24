;; title: augurrank-btc
;; version:
;; summary:
;; description:

(define-constant lead-height u100)
(define-constant pred-fee u100000)

(define-constant err-invalid-args (err u100))
(define-constant err-in-anticipation (err u101))
(define-constant err-premature-verify (err u102))
(define-constant err-invalid-height (err u103))
(define-constant err-contract-call (err u104))

(define-constant contract-deployer tx-sender)

(define-map last-ids principal uint)
(define-map preds
    { addr: principal, id: uint }
    { burn-height: uint, value: (string-ascii 4) }
)

(define-public (predict (value (string-ascii 4)))
    (begin
        (asserts! (or (is-eq value "up") (is-eq value "down")) err-invalid-args)

        (let
            (
                (last-id (default-to u0 (map-get? last-ids contract-caller)))
                (last-pred (default-to { burn-height: u0, value: "" } (map-get? preds { addr: contract-caller, id: last-id })))
                (id (+ last-id u1))
                (last-burn-height (get burn-height last-pred))
            )

            (asserts! (< last-burn-height (- burn-block-height lead-height)) err-in-anticipation)

            (map-set last-ids contract-caller id)
            (map-set preds
                { addr: contract-caller, id: id }
                { burn-height: burn-block-height, value: value }
            )

            (stx-transfer? pred-fee contract-caller contract-deployer)
        )
    )
)

(define-read-only (verify (addr principal) (id uint) (anchor-height uint) (target-height uint))
    (let
        (
            (pred (unwrap! (map-get? preds { addr: addr, id: id }) err-invalid-args))
            (anchor-burn-height (get burn-height pred))
            (target-burn-height (+ anchor-burn-height lead-height))
        )
        (asserts! (< target-burn-height burn-block-height) err-premature-verify)

        (let
            (
                (anchor-price (try! (get-price anchor-height anchor-burn-height)))
                (target-price (try! (get-price target-height target-burn-height)))
                (value (get value pred))
                (up-and-more
                    (and (is-eq value "up") (> target-price anchor-price))
                )
                (down-and-less
                    (and (is-eq value "down") (< target-price anchor-price))
                )
            )
            (ok {
                anchor-burn-height: anchor-burn-height,
                target-burn-height: target-burn-height,
                anchor-price: anchor-price,
                target-price: target-price,
                value: value,
                correct: (or up-and-more down-and-less)
            })
        )
    )
)

(define-private (get-price (height uint) (burn-height uint))
    (let
        (
            (last-id (unwrap! (get-stacks-block-info? id-header-hash (- height u1)) err-invalid-args))
            (id (unwrap! (get-stacks-block-info? id-header-hash height) err-invalid-args))
        )
        (at-block last-id
            (asserts! (is-eq burn-block-height (- burn-height u1)) err-invalid-height)
        )
        (at-block id
            (begin
                (asserts! (is-eq burn-block-height burn-height) err-invalid-height)
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
)
