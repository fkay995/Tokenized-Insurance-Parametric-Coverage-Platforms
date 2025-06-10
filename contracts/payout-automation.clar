;; Payout Automation Contract
;; Automates parametric payouts based on triggers

(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u400))
(define-constant ERR-PAYOUT-EXISTS (err u401))
(define-constant ERR-PAYOUT-NOT-FOUND (err u402))
(define-constant ERR-INSUFFICIENT-FUNDS (err u403))
(define-constant ERR-ALREADY-PROCESSED (err u404))

(define-map payouts
  { payout-id: (string-ascii 50) }
  {
    policy-id: (string-ascii 50),
    beneficiary: principal,
    amount: uint,
    trigger-event-id: uint,
    processed: bool,
    created-at: uint,
    processed-at: uint
  }
)

(define-map payout-calculations
  { policy-id: (string-ascii 50) }
  {
    base-amount: uint,
    multiplier: uint,
    max-payout: uint
  }
)

(define-data-var next-payout-id uint u1)
(define-data-var authorized-processors (list 5 principal) (list))
(define-data-var total-reserves uint u0)

;; Set payout calculation parameters
(define-public (set-payout-calculation (policy-id (string-ascii 50))
                                      (base-amount uint)
                                      (multiplier uint)
                                      (max-payout uint))
  (begin
    (asserts! (is-some (index-of (var-get authorized-processors) tx-sender)) ERR-NOT-AUTHORIZED)

    (map-set payout-calculations
      { policy-id: policy-id }
      {
        base-amount: base-amount,
        multiplier: multiplier,
        max-payout: max-payout
      }
    )

    (ok policy-id)
  )
)

;; Create payout
(define-public (create-payout (policy-id (string-ascii 50))
                             (beneficiary principal)
                             (trigger-value uint)
                             (trigger-event-id uint))
  (let (
    (payout-id (int-to-ascii (var-get next-payout-id)))
    (calc-params (unwrap! (map-get? payout-calculations { policy-id: policy-id }) (err u405)))
    (calculated-amount (calculate-payout-amount calc-params trigger-value))
  )
    (asserts! (is-some (index-of (var-get authorized-processors) tx-sender)) ERR-NOT-AUTHORIZED)
    (asserts! (is-none (map-get? payouts { payout-id: payout-id })) ERR-PAYOUT-EXISTS)

    (map-set payouts
      { payout-id: payout-id }
      {
        policy-id: policy-id,
        beneficiary: beneficiary,
        amount: calculated-amount,
        trigger-event-id: trigger-event-id,
        processed: false,
        created-at: block-height,
        processed-at: u0
      }
    )

    (var-set next-payout-id (+ (var-get next-payout-id) u1))
    (ok { payout-id: payout-id, amount: calculated-amount })
  )
)

;; Process payout
(define-public (process-payout (payout-id (string-ascii 50)))
  (let (
    (payout-info (unwrap! (map-get? payouts { payout-id: payout-id }) ERR-PAYOUT-NOT-FOUND))
    (amount (get amount payout-info))
    (beneficiary (get beneficiary payout-info))
  )
    (asserts! (is-some (index-of (var-get authorized-processors) tx-sender)) ERR-NOT-AUTHORIZED)
    (asserts! (not (get processed payout-info)) ERR-ALREADY-PROCESSED)
    (asserts! (>= (var-get total-reserves) amount) ERR-INSUFFICIENT-FUNDS)

    ;; Transfer payout to beneficiary
    (try! (as-contract (stx-transfer? amount tx-sender beneficiary)))

    ;; Update payout status
    (map-set payouts
      { payout-id: payout-id }
      (merge payout-info
             { processed: true, processed-at: block-height })
    )

    ;; Update reserves
    (var-set total-reserves (- (var-get total-reserves) amount))

    (ok amount)
  )
)

;; Calculate payout amount based on trigger value
(define-private (calculate-payout-amount (calc-params (tuple (base-amount uint) (multiplier uint) (max-payout uint))) (trigger-value uint))
  (let (
    (base (get base-amount calc-params))
    (multiplier (get multiplier calc-params))
    (max-amount (get max-payout calc-params))
    (calculated (* base (/ (* trigger-value multiplier) u100)))
  )
    (if (> calculated max-amount)
      max-amount
      calculated
    )
  )
)

;; Add funds to reserves
(define-public (add-reserves (amount uint))
  (begin
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    (var-set total-reserves (+ (var-get total-reserves) amount))
    (ok (var-get total-reserves))
  )
)

;; Add authorized processor
(define-public (add-processor (processor principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (var-set authorized-processors
             (unwrap-panic (as-max-len? (append (var-get authorized-processors) processor) u5)))
    (ok processor)
  )
)

;; Get payout info
(define-read-only (get-payout (payout-id (string-ascii 50)))
  (map-get? payouts { payout-id: payout-id })
)

;; Get payout calculation parameters
(define-read-only (get-payout-calculation (policy-id (string-ascii 50)))
  (map-get? payout-calculations { policy-id: policy-id })
)

;; Get total reserves
(define-read-only (get-total-reserves)
  (var-get total-reserves)
)
