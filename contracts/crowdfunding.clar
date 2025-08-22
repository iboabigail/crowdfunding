;; ------------------------------------------------
;; Crowdfunding Smart Contract
;; ------------------------------------------------

;; Constants
(define-constant contract-owner tx-sender)
(define-constant contract-address (as-contract tx-sender))

;; Features:
;; - Campaign creator sets a funding goal + deadline
;; - Contributors can send STX to support the campaign
;; - If goal is reached before deadline -> creator withdraws
;; - If not --> contributors can claim refunds
;; ------------------------------------------------

;; Error codes
(define-constant ERR-INVALID-GOAL (err u300))
(define-constant ERR-INVALID-DURATION (err u301))
(define-constant ERR-INVALID-AMOUNT (err u302))

;; Store current block height
(define-data-var current-block uint u0)

(define-constant ERR-NO-CAMPAIGN (err u100))
(define-constant ERR-NOT-CREATOR (err u101))
(define-constant ERR-ENDED (err u102))
(define-constant ERR-NOT-ENDED (err u103))
(define-constant ERR-GOAL-NOT-MET (err u104))
(define-constant ERR-ALREADY-REFUNDED (err u105))

;; Campaign storage
(define-data-var campaign-count uint u0)

(define-map campaigns
  { id: uint }
  { creator: principal, goal: uint, deadline: uint, raised: uint, open: bool }
)

;; Contributions
(define-map contributions
  { id: uint, donor: principal }
  { amount: uint, refunded: bool }
)

;; ------------------------------------------------
;; Create a campaign
;; ------------------------------------------------
(define-public (create-campaign (goal uint) (duration uint))
  (begin
    ;; Input validation
    (asserts! (> goal u0) ERR-INVALID-GOAL)
    (asserts! (> duration u0) ERR-INVALID-DURATION)
    (let ((id (+ (var-get campaign-count) u1))
          (deadline (+ (var-get current-block) duration)))
      (map-set campaigns { id: id }
        { creator: tx-sender,
          goal: goal,
          deadline: deadline,
          raised: u0,
          open: true })
      (var-set campaign-count id)
      (ok id))))

;; ------------------------------------------------
;; Contribute STX
;; ------------------------------------------------
;; Fixed contribute function to accept amount parameter and use stx-transfer?
(define-public (contribute (id uint) (amount uint))
  (begin
    ;; Input validation
    (asserts! (> amount u0) ERR-INVALID-AMOUNT)
    (asserts! (<= id (var-get campaign-count)) ERR-NO-CAMPAIGN)
    (let ((campaign (unwrap! (map-get? campaigns { id: id }) ERR-NO-CAMPAIGN)))
      (if (and (get open campaign) (> (get deadline campaign) (var-get current-block)))
        (begin
          ;; Transfer STX from contributor to contract
          (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
          ;; Record contribution and update campaign
          (ok (begin
            (map-set contributions { id: id, donor: tx-sender }
              { amount: amount, refunded: false })
            (map-set campaigns { id: id }
              { creator: (get creator campaign),
                goal: (get goal campaign),
                deadline: (get deadline campaign),
                raised: (+ (get raised campaign) amount),
                open: true })
            "Contribution successful")))
        ERR-ENDED))))


;; ------------------------------------------------
;; Withdraw by creator (if goal met)
;; ------------------------------------------------
(define-public (withdraw (id uint))
  (begin
    (asserts! (<= id (var-get campaign-count)) ERR-NO-CAMPAIGN)
    (let ((campaign (unwrap! (map-get? campaigns { id: id }) ERR-NO-CAMPAIGN)))
      (asserts! (is-eq tx-sender (get creator campaign)) ERR-NOT-CREATOR)
      (if (and (>= (get raised campaign) (get goal campaign)) (>= (var-get current-block) (get deadline campaign)))
        (begin
          (try! (stx-transfer? (get raised campaign) (as-contract tx-sender) (get creator campaign)))
          (ok (begin
            (map-set campaigns { id: id }
              { creator: (get creator campaign),
                goal: (get goal campaign),
                deadline: (get deadline campaign),
                raised: (get raised campaign),
                open: false })
            "Funds withdrawn")))
        ERR-GOAL-NOT-MET))))

;; ------------------------------------------------
;; Refund contributors if goal not met
;; ------------------------------------------------
(define-public (refund (id uint))
  (begin
    (asserts! (<= id (var-get campaign-count)) ERR-NO-CAMPAIGN)
    (let ((contrib (unwrap! (map-get? contributions { id: id, donor: tx-sender }) (err u201)))
          (campaign (unwrap! (map-get? campaigns { id: id }) ERR-NO-CAMPAIGN)))
      (asserts! (not (get refunded contrib)) ERR-ALREADY-REFUNDED)
      (if (and (>= (var-get current-block) (get deadline campaign)) (< (get raised campaign) (get goal campaign)))
        (begin
          (try! (stx-transfer? (get amount contrib) (as-contract tx-sender) tx-sender))
          (ok (begin
            (map-set contributions { id: id, donor: tx-sender }
              { amount: (get amount contrib), refunded: true })
            "Refund successful")))
        ERR-NOT-ENDED))))

;; ------------------------------------------------
;; Read-only helpers
;; ------------------------------------------------
(define-read-only (get-campaign (id uint))
  (let ((campaign (unwrap! (map-get? campaigns { id: id }) ERR-NO-CAMPAIGN)))
    (ok campaign)))

(define-read-only (get-contribution (id uint) (donor principal))
  (let ((contrib (unwrap! (map-get? contributions { id: id, donor: donor }) (err u202))))
    (ok contrib)))

(define-read-only (get-total-campaigns)
  (ok (var-get campaign-count)))
