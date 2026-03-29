package main

import (
	"context"
	"io"
	"log/slog"
	"math/rand"
	"net/http"
	"strconv"
	"time"

	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/attribute"
	"go.opentelemetry.io/otel/codes"
	"go.opentelemetry.io/otel/metric"
	"go.opentelemetry.io/otel/trace"

	"go.opentelemetry.io/contrib/bridges/otelslog"
)

const name = "go.opentelemetry.io/contrib/examples/dice"

var (
	tracer   = otel.Tracer(name)
	meter    = otel.Meter(name)
	rollCnt  metric.Int64Counter
	rollHist metric.Int64Histogram
)

func init() {
	var err error
	rollCnt, err = meter.Int64Counter("dice.rolls",
		metric.WithDescription("The number of rolls by roll value"),
		metric.WithUnit("{roll}"))
	if err != nil {
		panic(err)
	}

	rollHist, err = meter.Int64Histogram("dice.roll_distribution",
		metric.WithDescription("Distribution of dice roll values"),
		metric.WithUnit("{roll}"))
	if err != nil {
		panic(err)
	}
}

func rolldice(w http.ResponseWriter, r *http.Request) {
	ctx, span := tracer.Start(r.Context(), "roll-request")
	defer span.End()

	logger := otelslog.NewLogger(name)

	player := r.PathValue("player")
	if player == "" {
		player = "Anonymous"
	}
	span.SetAttributes(attribute.String("player.name", player))

	logger.InfoContext(ctx, "High-level roll request received", "player", player)

	// Step 1: Simulate Roll Verification (Nested Span)
	roll := verifyRoll(ctx, logger)

	// Step 2: Randomly simulate a "Database Failure" (Errors in Trace)
	if rand.Intn(10) == 0 { // 10% chance of failure
		logger.ErrorContext(ctx, "Simulation: Persistence failure in pseudo-database", "player", player)
		span.SetStatus(codes.Error, "Internal simulation failure")
		http.Error(w, "Simulated database failure", http.StatusInternalServerError)
		return
	}

	// Step 3: Simulate Result Storage (Nested Span)
	storeResult(ctx, logger, roll)

	// Update Metrics
	rollValueAttr := attribute.Int("roll.value", roll)
	rollCnt.Add(ctx, 1, metric.WithAttributes(rollValueAttr))
	rollHist.Record(ctx, int64(roll), metric.WithAttributes(rollValueAttr))

	resp := strconv.Itoa(roll) + "\n"
	if _, err := io.WriteString(w, resp); err != nil {
		logger.ErrorContext(ctx, "Write failed", "error", err)
	}
}

func verifyRoll(ctx context.Context, logger *slog.Logger) int {
	_, span := tracer.Start(ctx, "verify-roll")
	defer span.End()

	span.AddEvent("validation_started", trace.WithAttributes(attribute.String("check", "reliability")))
	
	// Simulate some work
	time.Sleep(10 * time.Millisecond)
	roll := 1 + rand.Intn(6)
	
	span.SetAttributes(attribute.Int("roll.result", roll))
	logger.InfoContext(ctx, "Roll verified successfully", "result", roll)
	
	span.AddEvent("validation_completed")
	return roll
}

func storeResult(ctx context.Context, logger *slog.Logger, roll int) {
	_, span := tracer.Start(ctx, "store-result")
	defer span.End()

	span.SetAttributes(attribute.String("db.operation", "INSERT"), attribute.String("db.table", "rolls"))
	
	// Simulate I/O latency
	time.Sleep(50 * time.Millisecond)
	logger.InfoContext(ctx, "Result committed to simulated database", "value", roll)
}
