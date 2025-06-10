;; Data Source Contract
;; Manages parametric data sources and validation

(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u200))
(define-constant ERR-SOURCE-EXISTS (err u201))
(define-constant ERR-SOURCE-NOT-FOUND (err u202))
(define-constant ERR-INVALID-DATA (err u203))

(define-map data-sources
  { source-id: (string-ascii 50) }
  {
    name: (string-ascii 100),
    endpoint: (string-ascii 200),
    verified: bool,
    reliability-score: uint,
    last-update: uint,
    data-type: (string-ascii 20)
  }
)

(define-map data-feeds
  { source-id: (string-ascii 50), timestamp: uint }
  {
    value: uint,
    validator: principal,
    block-height: uint
  }
)

(define-data-var authorized-validators (list 10 principal) (list))

;; Add a new data source
(define-public (add-source (source-id (string-ascii 50))
                          (name (string-ascii 100))
                          (endpoint (string-ascii 200))
                          (data-type (string-ascii 20)))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (is-none (map-get? data-sources { source-id: source-id })) ERR-SOURCE-EXISTS)

    (map-set data-sources
      { source-id: source-id }
      {
        name: name,
        endpoint: endpoint,
        verified: false,
        reliability-score: u50,
        last-update: u0,
        data-type: data-type
      }
    )

    (ok source-id)
  )
)

;; Verify a data source
(define-public (verify-source (source-id (string-ascii 50)))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (is-some (map-get? data-sources { source-id: source-id })) ERR-SOURCE-NOT-FOUND)

    (map-set data-sources
      { source-id: source-id }
      (merge (unwrap-panic (map-get? data-sources { source-id: source-id }))
             { verified: true })
    )

    (ok true)
  )
)

;; Submit data feed
(define-public (submit-data (source-id (string-ascii 50)) (value uint))
  (let ((timestamp (unwrap-panic (get-block-info? time (- block-height u1)))))
    (asserts! (is-some (index-of (var-get authorized-validators) tx-sender)) ERR-NOT-AUTHORIZED)
    (asserts! (is-some (map-get? data-sources { source-id: source-id })) ERR-SOURCE-NOT-FOUND)

    (map-set data-feeds
      { source-id: source-id, timestamp: timestamp }
      {
        value: value,
        validator: tx-sender,
        block-height: block-height
      }
    )

    ;; Update last-update timestamp
    (map-set data-sources
      { source-id: source-id }
      (merge (unwrap-panic (map-get? data-sources { source-id: source-id }))
             { last-update: timestamp })
    )

    (ok value)
  )
)

;; Add authorized validator
(define-public (add-validator (validator principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (var-set authorized-validators
             (unwrap-panic (as-max-len? (append (var-get authorized-validators) validator) u10)))
    (ok validator)
  )
)

;; Get data source info
(define-read-only (get-source (source-id (string-ascii 50)))
  (map-get? data-sources { source-id: source-id })
)

;; Get latest data feed
(define-read-only (get-latest-data (source-id (string-ascii 50)))
  (let ((source-info (unwrap-panic (map-get? data-sources { source-id: source-id }))))
    (map-get? data-feeds { source-id: source-id, timestamp: (get last-update source-info) })
  )
)

;; Check if source is verified
(define-read-only (is-source-verified (source-id (string-ascii 50)))
  (match (map-get? data-sources { source-id: source-id })
    source-data (get verified source-data)
    false
  )
)
