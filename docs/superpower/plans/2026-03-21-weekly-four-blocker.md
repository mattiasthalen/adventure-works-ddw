# Weekly Four-Blocker Report Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Generate a weekly report markdown file with 4 output metrics and 12 input metrics, each with result, NL prompt, and SQL.

**Architecture:** Hand 16 natural language questions to `/daana:query` (already bootstrapped on `dev` profile, latest snapshot, no cutoff). Capture each result + generated SQL. Assemble into a markdown report with collapsed prompt/SQL sections.

**Tech Stack:** `/daana:query` skill, Markdown with `<details>` tags.

**Worktree:** `.worktrees/weekly-report` on branch `feat/weekly-report`

**Spec:** `docs/superpower/specs/2026-03-21-weekly-four-blocker-design.md`

---

## Pre-Requisites

The `/daana:query` session must already be bootstrapped:
- Connection profile: `dev` (PostgreSQL, localhost:5442, customerdb)
- Time dimension: Latest, don't ask again
- Cutoff: Current, no cutoff
- Execution consent: Yes, don't ask again

If not already bootstrapped, invoke `/daana:query` and complete Phase 1-2 first.

---

## Task 1: Block 1 — Revenue (4 questions, parallel)

Hand these 4 questions to `/daana:query` as a multi-question batch:

1. **Total Revenue (output):** "What is the total revenue across all sales orders?"
2. **Discount Depth (input):** "What is the average special offer discount percentage applied to order lines?"
3. **Sales Quota Coverage (input):** "What is the sales quota vs YTD attainment for each sales person?"
4. **List Price Positioning (input):** "What is the quantity-weighted average list price of products sold?"

**Capture:** Result, NL prompt, and generated SQL for each.

---

## Task 2: Block 2 — Gross Margin (4 questions, parallel)

Hand these 4 questions to `/daana:query` as a multi-question batch:

1. **Gross Margin % (output):** "What is the gross margin percentage based on line-level revenue and standard cost?"
2. **Standard Cost per Unit (input):** "What is the quantity-weighted average standard cost of products sold?"
3. **Make vs Buy Mix (input):** "What percentage of products are manufactured in-house vs purchased?"
4. **Vendor Credit Quality (input):** "What is the average credit rating of active vendors?"

**Capture:** Result, NL prompt, and generated SQL for each.

---

## Task 3: Block 3 — Fulfillment Cycle Time (4 questions, parallel)

Hand these 4 questions to `/daana:query` as a multi-question batch:

1. **Avg Fulfillment Days (output):** "What is the average number of days between order date and ship date?"
2. **Manufacturing Lead Time (input):** "What is the average days to manufacture for products on sold order lines?"
3. **Scrap Rate (input):** "What is the scrap rate on work orders (scrapped qty / order qty)?"
4. **Safety Stock Adequacy (input):** "What is the average safety stock level across all products?"

**Capture:** Result, NL prompt, and generated SQL for each.

---

## Task 4: Block 4 — Customer Breadth (4 questions, parallel)

Hand these 4 questions to `/daana:query` as a multi-question batch:

1. **Unique Customers (output):** "How many unique customers have placed at least one sales order?"
2. **Territory Coverage (input):** "How many customers are in each sales territory?"
3. **Online Order Ratio (input):** "What percentage of sales orders are placed online?"
4. **Sales Person Reach (input):** "What is the average number of unique customers per sales person?"

**Capture:** Result, NL prompt, and generated SQL for each.

---

## Task 5: Assemble Report

**Step 1:** Create `weekly-report.md` at project root in the worktree.

Format per the spec — each metric:
- Result value + brief business summary (visible)
- NL prompt + SQL in collapsed `<details><summary>Prompt & SQL</summary>` block

**Step 2:** Commit the report.

**Step 3:** Push branch and create PR.

---

## Parallelization

Tasks 1-4 are independent — all 4 blocks can run as parallel multi-question batches via `/daana:query`.

Task 5 depends on tasks 1-4.
