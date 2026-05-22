# Additions — quality-filter notes

**Tracked in:** [edge-discovery.md](./edge-discovery.md) as **EDGE-3.11–3.16**, **EDGE-5.5**, **EDGE-6.7–6.8** (one ID → one backtest vs P2-C).

---


> The system already finds real directional moves.
> The problem is not profit extraction.
> The problem is too many low-quality entries contaminating the edge.

That changes the optimization direction completely.

You should NOT focus primarily on:

* larger TP
* tighter SL
* fancy trailing
* martingale recovery

Because your metrics already prove:

* MFE correlation is high
* RR structure works
* winners expand correctly
* losses fail early

That means:

# Entry selection and failure containment are the core problem.

And this is actually good news because it is easier to improve PF from:

* 0.96 → 1.10
  than trying to rescue a broken exit engine.

---

# What Your System Really Is

Your EA is fundamentally:

# “Volatility Expansion Continuation After Compression”

NOT:

* breakout trading
* mean reversion
* trend following

It specifically likes:

* compression
* decisive release
* real momentum continuation
* liquidity session participation

That is important because your future filters must reinforce THIS behavior.

---

# What Is Currently Killing PF

Your losses come from:

* fake expansions
* overlap churn
* exhaustion breaks
* late-stage continuation
* micro liquidity grabs
* weak displacement
* structure breaks into nearby resistance/support
* expansion without follow-through

Your current AND-chain detects:

* “movement exists”

But not:

* “movement quality is high”

That distinction is where PF improvements live.

---

# The Highest-Value Improvements

Priority ordered.

---

# 1. Expansion Quality Filter (Highest Value)

You already discovered:

* BB expansion ≥1.08 was the turning point

This is VERY important.

The market is telling you:

> Weak releases are noise.

You should deepen this idea.

---

## Add Expansion Persistence

Current:

* one-bar BB expansion

Problem:

* one candle spikes then dies

Add:

* require expansion persistence

Example:

* BB width expanding for 2 consecutive closed candles

OR:

* current BB width > prior width
* AND prior width > width before that

This removes:

* one-tick fake releases

This alone may materially improve WR.

---

# 2. Distance-To-Obstacle Filter (Extremely Important)

One of the biggest hidden killers in breakout systems:

# breaking directly into nearby structure

Example:

* bullish break
* but resistance is 4 pips above

Result:

* instant failure

You need:

# “room-to-target” validation

---

## Add Minimum Free Space Filter

For buys:

* nearest swing high / local resistance must be:

  * ≥ X ATR away

For sells:

* nearest support must be:

  * ≥ X ATR away

Example:

* require at least:

  * `0.5 ATR`
  * or `0.7R`
  * free space

This is one of the highest-value filters in momentum systems.

---

# 3. Trend Exhaustion Filter

A massive source of losses:

* entering after already extended moves

Especially during:

* NY overlap churn

---

## Add Distance From EMA Filter

Current:

* EMA alignment only

Problem:

* alignment still true after huge extension

Add:

* max distance from EMA

Example:

* entry candle close must not exceed:

  * `1.2 ATR from fast EMA`

This prevents:

* buying vertical exhaustion
* selling capitulation dumps

Huge improvement potential.

---

# 4. Volatility Regime Filter (Very High Value)

Your system needs:

* enough volatility to expand
* but not chaos

Right now you only check:

* ATR minimum

You also need:

# ATR sanity ceiling

Avoid:

* hyper-volatile chaos bars

---

## Add ATR Regime Band

Trade only if:

* ATR between:

  * lower threshold
  * upper threshold

Example:

* avoid top 10–15% ATR extremes

This filters:

* news spikes
* overlap chaos
* exhaustion volatility

Likely strong PF improvement.

---

# 5. Candle Efficiency Filter

Some displacement candles:

* are mostly wick
* close weakly
* have poor continuation probability

---

## Add Close Strength Requirement

For buys:

* close must be in upper X% of candle range

For sells:

* close must be in lower X%

Example:

* bullish close ≥ 70% candle position

This detects:

* commitment
* not rejection

Very valuable continuation filter.

---

# 6. Multi-Bar Compression Quality

Not all squeezes are equal.

Some are:

* random dead chop

Others:

* real energy buildup

---

## Add Compression Stability

Require:

* BB width compressed for:

  * N consecutive bars

Example:

* squeeze active for:

  * 4–8 bars minimum

This avoids:

* tiny random compressions

Often improves breakout quality substantially.

---

# 7. Loss Containment Logic (Very Important)

Your losers fail early.

This is gold.

You should exploit that.

---

# Add Time-Based Failure Exit

If trade does NOT:

* move at least:

  * X fraction of R
    within:
* Y candles

Then:

* close early

Example:

* if after 5 candles:

  * price has not reached +0.3R
* exit

This removes:

* dead trades
* churn
* stagnant overlap losses

This is MUCH better than random trailing stops.

---

# 8. MFE-Based Partial Protection

Since winners move properly:

Use:

* structure-based partial protection

---

## Suggested Flow

At:

* +0.8R:

  * move SL to BE

At:

* +1.2R:

  * partial close 30–50%

Leave runner:

* full TP

This:

* stabilizes equity curve
* reduces psychological DD
* improves recovery factor

WITHOUT damaging RR heavily.

---

# 9. Overlap Churn Filter (Likely High Impact)

Your own data strongly suggests:

* 13–15 broker time may be noisy churn

Do NOT blindly remove it yet.

Instead:

# tighten conditions during overlap

Example:
During overlap:

* require:

  * stronger displacement
  * larger BB expansion
  * larger structure penetration

Adaptive thresholds by hour are powerful.

---

# 10. Consecutive Loss Regime Protection

Your long streaks imply:

* market regime mismatch

Add:

* temporary self-throttling

---

## Example

After:

* 4 consecutive losses

Then:

* require:

  * stronger BB expansion
  * larger displacement

OR:

* pause for:

  * 30–60 minutes

This is not martingale logic.

This is:

# regime instability protection.

Very practical.

---

# What You Should NOT Prioritize Yet

Low value right now:

* trailing stop experiments
* wider TP
* tighter SL
* adding more indicators
* RSI/MACD clutter
* AI entries
* martingale recovery
* session breakout logic
* high volume thresholds

Your data already disproves several of these.

---

# Most Powerful Potential Improvements

If I ranked expected PF impact:

| Addition                    | Expected Impact |
| --------------------------- | --------------- |
| Distance-to-obstacle filter | VERY HIGH       |
| Expansion persistence       | VERY HIGH       |
| EMA overextension filter    | VERY HIGH       |
| Time-based dead-trade exit  | HIGH            |
| Close strength filter       | HIGH            |
| ATR regime ceiling          | HIGH            |
| Adaptive overlap thresholds | HIGH            |
| Compression duration filter | MEDIUM-HIGH     |
| Partial BE protection       | MEDIUM          |
| Trailing stops              | LOW-MEDIUM      |

---

# The Most Important Insight

Your system likely does NOT need:

* more trades
* bigger RR

It needs:

# fewer stupid trades.

That is the entire optimization problem now.

And your current metrics already prove:

* the edge exists underneath the noise.

The next stage is:

# selective aggression.

Not:

# more complexity.
