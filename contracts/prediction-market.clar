
;; prediction-market
;; A decentralized prediction market contract allowing users to create markets,
;; trade shares on outcomes, provide liquidity, and resolve markets via oracles

;; constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-invalid-params (err u103))
(define-constant err-insufficient-funds (err u104))
(define-constant err-market-closed (err u105))
(define-constant err-market-not-resolved (err u106))
(define-constant err-market-already-resolved (err u107))
(define-constant err-dispute-period-active (err u108))
(define-constant err-dispute-period-expired (err u109))
(define-constant err-already-claimed (err u110))
(define-constant err-no-winnings (err u111))
(define-constant err-market-not-finalized (err u112))

;; data maps and vars
(define-data-var contract-initialized bool false)
(define-data-var next-market-id uint u1)
(define-data-var protocol-fee-percentage uint u100) ;; 1% default
(define-data-var min-dispute-stake uint u1000000) ;; 1 STX default
(define-data-var default-dispute-period-length uint u144) ;; ~24 hours in blocks

;; Oracle management
(define-map oracles principal { reputation: uint, is-active: bool })
(define-data-var oracle-list (list 100 principal) (list))

;; Market data structure
(define-map markets uint {
    creator: principal,
    description: (string-utf8 500),
    category: (string-ascii 50),
    outcomes: (list 10 (string-utf8 100)),
    resolution-time: uint,
    closing-time: uint,
    fee-percentage: uint,
    oracle: principal,
    oracle-fee: uint,
    min-trade-amount: uint,
    additional-data: (optional (string-utf8 1000)),
    status: (string-ascii 20), ;; "active", "closed", "resolved", "disputed", "finalized"
    resolved-outcome: (optional uint),
    resolution-block: (optional uint),
    total-liquidity: uint,
    outcome-reserves: (list 10 uint),
    dispute-deadline: (optional uint),
    disputed-outcome: (optional uint),
    dispute-stake: uint
})

;; Liquidity positions
(define-map liquidity-positions { market-id: uint, provider: principal } {
    shares: uint,
    share-percentage: uint
})

;; User positions for each outcome
(define-map user-positions { market-id: uint, user: principal, outcome: uint } {
    shares: uint,
    claimed: bool
})

;; Dispute stakes 
(define-map dispute-stakes { market-id: uint, disputer: principal } uint)

;; private functions

;; Check if caller is contract owner
(define-private (is-owner)
    (is-eq tx-sender CONTRACT-OWNER))

;; Check if oracle is authorized and active
(define-private (is-authorized-oracle (oracle principal))
    (match (map-get? oracles oracle)
        oracle-data (get is-active oracle-data)
        false))

;; public functions

;; Initialize the contract with a list of oracles
(define-public (initialize (initial-oracles (list 100 principal)))
    (begin
        (asserts! (is-owner) err-owner-only)
        (asserts! (not (var-get contract-initialized)) (err u113))
        
        ;; Add initial oracles
        (map add-oracle-internal initial-oracles)
        (var-set oracle-list initial-oracles)
        (var-set contract-initialized true)
        (ok true)))

;; Internal function to add oracle
(define-private (add-oracle-internal (oracle principal))
    (map-set oracles oracle { reputation: u100, is-active: true }))

;; Add a new oracle (owner only)
(define-public (add-oracle (oracle principal))
    (begin
        (asserts! (is-owner) err-owner-only)
        (map-set oracles oracle { reputation: u100, is-active: true })
        (let ((current-list (var-get oracle-list)))
            (var-set oracle-list (unwrap! (as-max-len? (append current-list oracle) u100) err-invalid-params)))
        (ok true)))

;; Update oracle reputation (owner only)
(define-public (update-oracle-reputation (oracle principal) (reputation uint))
    (begin
        (asserts! (is-owner) err-owner-only)
        (asserts! (<= reputation u100) err-invalid-params)
        (match (map-get? oracles oracle)
            oracle-data (begin
                (map-set oracles oracle (merge oracle-data { reputation: reputation }))
                (ok true))
            err-not-found)))

;; Governance functions
(define-public (set-protocol-fee-percentage (fee-percentage uint))
    (begin
        (asserts! (is-owner) err-owner-only)
        (asserts! (<= fee-percentage u1000) err-invalid-params) ;; Max 10%
        (var-set protocol-fee-percentage fee-percentage)
        (ok true)))

(define-public (set-min-dispute-stake (amount uint))
    (begin
        (asserts! (is-owner) err-owner-only)
        (asserts! (> amount u0) err-invalid-params)
        (var-set min-dispute-stake amount)
        (ok true)))

(define-public (set-default-dispute-period-length (blocks uint))
    (begin
        (asserts! (is-owner) err-owner-only)
        (asserts! (> blocks u0) err-invalid-params)
        (var-set default-dispute-period-length blocks)
        (ok true)))
