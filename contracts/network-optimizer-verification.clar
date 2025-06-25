;; Network Optimizer Verification Contract
;; Validates telecommunications network optimizers

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_OPTIMIZER_NOT_FOUND (err u101))
(define-constant ERR_INVALID_METRICS (err u102))

;; Data structures
(define-map verified-optimizers
  { optimizer-id: uint }
  {
    owner: principal,
    performance-score: uint,
    verification-timestamp: uint,
    is-active: bool
  }
)

(define-map optimizer-metrics
  { optimizer-id: uint }
  {
    latency-reduction: uint,
    throughput-improvement: uint,
    error-rate-reduction: uint,
    uptime-percentage: uint
  }
)

(define-data-var next-optimizer-id uint u1)

;; Register a new network optimizer
(define-public (register-optimizer (latency-reduction uint) (throughput-improvement uint) (error-rate-reduction uint) (uptime-percentage uint))
  (let ((optimizer-id (var-get next-optimizer-id)))
    (if (and
          (> latency-reduction u0)
          (> throughput-improvement u0)
          (< error-rate-reduction u100)
          (> uptime-percentage u90))
      (begin
        (map-set verified-optimizers
          { optimizer-id: optimizer-id }
          {
            owner: tx-sender,
            performance-score: (calculate-performance-score latency-reduction throughput-improvement error-rate-reduction uptime-percentage),
            verification-timestamp: block-height,
            is-active: true
          }
        )
        (map-set optimizer-metrics
          { optimizer-id: optimizer-id }
          {
            latency-reduction: latency-reduction,
            throughput-improvement: throughput-improvement,
            error-rate-reduction: error-rate-reduction,
            uptime-percentage: uptime-percentage
          }
        )
        (var-set next-optimizer-id (+ optimizer-id u1))
        (ok optimizer-id))
      ERR_INVALID_METRICS)))

;; Calculate performance score based on metrics
(define-private (calculate-performance-score (latency-reduction uint) (throughput-improvement uint) (error-rate-reduction uint) (uptime-percentage uint))
  (+
    (/ (* latency-reduction u25) u100)
    (/ (* throughput-improvement u25) u100)
    (/ (* error-rate-reduction u25) u100)
    (/ (* uptime-percentage u25) u100)))

;; Get optimizer details
(define-read-only (get-optimizer (optimizer-id uint))
  (map-get? verified-optimizers { optimizer-id: optimizer-id }))

;; Get optimizer metrics
(define-read-only (get-optimizer-metrics (optimizer-id uint))
  (map-get? optimizer-metrics { optimizer-id: optimizer-id }))

;; Deactivate optimizer (only owner)
(define-public (deactivate-optimizer (optimizer-id uint))
  (let ((optimizer (unwrap! (map-get? verified-optimizers { optimizer-id: optimizer-id }) ERR_OPTIMIZER_NOT_FOUND)))
    (if (is-eq tx-sender (get owner optimizer))
      (begin
        (map-set verified-optimizers
          { optimizer-id: optimizer-id }
          (merge optimizer { is-active: false }))
        (ok true))
      ERR_UNAUTHORIZED)))
