
;; title: playground
;; version:
;; summary:
;; description:

(define-read-only (get-heights (height uint))
    (let
        (
            (id (unwrap! (get-stacks-block-info? id-header-hash height) (err u100)))
            (burn-height (at-block id burn-block-height))
        ) 
        (ok { burn-height: burn-height, height: height })
    )
)