PowStat
================

- [PowStat](#powstat)
  - [Disclaimer](#disclaimer)
  - [Overview](#overview)
    - [Client-side R functions](#client-side-r-functions)
  - [Installation](#installation)
  - [API configuration](#api-configuration)
- [1. Continuous endpoint: two-arm MDD
  calculation](#1-continuous-endpoint-two-arm-mdd-calculation)
  - [Overview](#overview-1)
  - [Function signature](#function-signature)
  - [Arguments](#arguments)
  - [Example](#example)
  - [Returned object](#returned-object)
  - [Output interpretation](#output-interpretation)
- [2. Time-to-event endpoint: two-arm logrank
  design](#2-time-to-event-endpoint-two-arm-logrank-design)
  - [Overview](#overview-2)
  - [Function signature](#function-signature-1)
  - [Arguments](#arguments-1)
  - [Input modes](#input-modes)
    - [Mode 1: accrual rate plus accrual
      duration](#mode-1-accrual-rate-plus-accrual-duration)
    - [Mode 2: accrual rate plus total sample
      size](#mode-2-accrual-rate-plus-total-sample-size)
    - [Mode 3: accrual duration plus total study
      duration](#mode-3-accrual-duration-plus-total-study-duration)
  - [Fixed design example](#fixed-design-example)
  - [Group sequential design example](#group-sequential-design-example)
  - [Returned object](#returned-object-1)
  - [Output interpretation](#output-interpretation-1)
    - [Study Parameters](#study-parameters)
    - [Survival and Dropout Model](#survival-and-dropout-model)
    - [Sample Size Information](#sample-size-information)
    - [Event and Information Summary](#event-and-information-summary)
    - [Accrual and Study Duration
      Summary](#accrual-and-study-duration-summary)
    - [Analysis-Look Details](#analysis-look-details)
- [3. Binary endpoint: two-arm superiority
  design](#3-binary-endpoint-two-arm-superiority-design)
  - [Overview](#overview-3)
  - [Function signature](#function-signature-2)
  - [Arguments](#arguments-2)
  - [Example](#example-1)
  - [Example with unequal allocation](#example-with-unequal-allocation)
  - [Returned object](#returned-object-2)
  - [Output interpretation](#output-interpretation-2)
  - [Notes on exact Fisher
    calculation](#notes-on-exact-fisher-calculation)
- [4. Binary endpoint: single-arm exact binomial
  design](#4-binary-endpoint-single-arm-exact-binomial-design)
  - [Overview](#overview-4)
  - [Function signature](#function-signature-3)
  - [Arguments](#arguments-3)
  - [Example: greater alternative](#example-greater-alternative)
  - [Example: less alternative](#example-less-alternative)
  - [Returned object](#returned-object-3)
  - [Showing all valid designs](#showing-all-valid-designs)
  - [Power curve](#power-curve)
- [Input validation](#input-validation)
  - [Common validation rules](#common-validation-rules)
    - [Continuous two-arm design](#continuous-two-arm-design)
    - [Time-to-event logrank design](#time-to-event-logrank-design)
    - [Binary two-arm design](#binary-two-arm-design)
    - [Binary single-arm design](#binary-single-arm-design)
- [Returned S3 classes and print
  methods](#returned-s3-classes-and-print-methods)
- [Dependencies](#dependencies)
  - [Client-side dependencies](#client-side-dependencies)
- [Detailed methodological notes](#detailed-methodological-notes)
  - [Continuous endpoint MDD](#continuous-endpoint-mdd)
  - [Time-to-event event probability under uniform
    accrual](#time-to-event-event-probability-under-uniform-accrual)
  - [Group sequential design](#group-sequential-design)
  - [Time-to-event MDD](#time-to-event-mdd)
  - [Binary two-arm Z unpooled sample
    size](#binary-two-arm-z-unpooled-sample-size)
  - [Binary single-arm exact
    binomial](#binary-single-arm-exact-binomial)
- [Example workflow](#example-workflow)
- [Citation](#citation)
- [License](#license)
- [Contact](#contact)

# PowStat

<!-- badges: start -->

<!--
[![R-CMD-check](https://github.com/YOUR-ORG/PowStat/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/YOUR-ORG/PowStat/actions/workflows/R-CMD-check.yaml)
[![Codecov test coverage](https://codecov.io/gh/YOUR-ORG/PowStat/branch/main/graph/badge.svg)](https://app.codecov.io/gh/YOUR-ORG/PowStat)
-->

<!-- badges: end -->

## Disclaimer

This software is provided for research and educational purposes only. It
is not intended to provide medical advice, clinical recommendations, or
regulatory guidance. Users are responsible for independently validating
all results before use in any clinical, regulatory, or commercial
decision-making.

## Overview

`PowStat` is an R package for clinical trial design and statistical
power/sample-size calculations.

The package is organized as a lightweight **client-side R interface**
backed by a **server-side computation engine**. The client-side
functions validate inputs, send calculation requests to the PowStat API,
receive structured JSON results, convert them into R data frames, and
provide formatted print methods.

Currently, `PowStat` supports the following design modules:

1.  **Continuous endpoint, two-arm design**
    - Minimal Detectable Difference, MDD
    - Sample size calculation
2.  **Time-to-event endpoint, two-arm design**
    - Fixed and group sequential designs
    - Sample size summary
    - Event targets
    - Calendar duration
    - Efficacy boundaries
    - Minimum detectable hazard ratio by analysis look
3.  **Binary endpoint, two-arm design**
    - Z pooled method
    - Z unpooled method
    - Fisher exact test by enumeration
    - Optional fixed sample size evaluation
4.  **Binary endpoint, single-arm design**
    - Exact binomial sample size search
    - Critical point and rejection region
    - Attained alpha and power
    - Optional fixed sample size evaluation

------------------------------------------------------------------------

### Client-side R functions

The user-facing functions are:

| Function                  | Endpoint type | Design            |
|---------------------------|---------------|-------------------|
| `ps_continuous_two_arm()` | Continuous    | Two-arm design    |
| `ps_tte_logrank()`        | Time-to-event | Two-arm design    |
| `ps_binary_two_arm()`     | Binary        | Two-arm design    |
| `ps_binary_single_arm()`  | Binary        | Single-arm design |

Each client-side function:

1.  Checks core input validity.
2.  Builds a parameter list.
3.  Calls the PowStat API through `powstat_api_call()`.
4.  Converts returned objects into data frames.
5.  Assigns a custom S3 class.
6.  Supports a custom `print()` method.

## Installation

You can install the development version from GitHub:

``` r
# install.packages("devtools")
devtools::install_github("chenchaostat/PowStat")
```

Or using `remotes`:

``` r
# install.packages("remotes")
remotes::install_github("chenchaostat/PowStat")
```

Then load the package:

``` r
library(PowStat)
```

------------------------------------------------------------------------

## API configuration

`PowStat` client-side functions call a backend API through
`powstat_api_call()`.

Depending on your implementation, the API base URL may be configured
through an environment variable, a package option, or another
configuration helper.

A typical setup may look like:

``` r
Sys.setenv(POWSTAT_API_BASE_URL = "https://your-powstat-api.example.com")
```

or:

``` r
options(powstat.api_base_url = "https://your-powstat-api.example.com")
```

Please adapt this section to your actual deployment configuration.

------------------------------------------------------------------------

# 1. Continuous endpoint: two-arm MDD calculation

## Overview

The function `ps_continuous_two_arm()` calculates the Minimal Detectable
Difference (MDD), for a continuous endpoint in a two-arm parallel
design.

It compares two approaches:

1.  **Method 1: rpact sample size calculation**
    - Uses `rpact::getSampleSizeMeans()`.
    - The input `alternative` is treated as the hypothesized mean
      difference.
    - The returned sample size and critical effect scale are reported.
2.  **Method 2: Formula-based MDD calculation**
    - Uses the user-provided per-arm sample size.
    - Computes the standard error and MDD analytically.

For a two-arm design, the formula is:

$$
\text{MDD} = (Z_{\alpha} + Z_{\beta}) \times SD \times \sqrt{\frac{1}{n_1} + \frac{1}{n_2}}
$$

where:

- $SD$ is the common standard deviation.
- $n_1$ is the group 1 sample size.
- $n_2$ is the group 2 sample size.
- $Z_{\alpha}$ is the critical value for the significance level.
- $Z_{\beta}$ is the normal quantile corresponding to power.

For a one-sided test:

$$
Z_{\alpha} = \Phi^{-1}(1 - \alpha)
$$

For a two-sided test:

$$
Z_{\alpha} = \Phi^{-1}(1 - \alpha / 2)
$$

## Function signature

``` r
ps_continuous_two_arm(
  groups = 2,
  normalApproximation = FALSE,
  alpha = 0.025,
  beta = 0.2,
  alternative,
  sided = 1,
  stDev,
  allocationRatioPlanned = 1,
  singlearmsamplesize,
  digits = 5
)
```

## Arguments

| Argument | Description |
|----|----|
| `groups` | Number of groups. Supported values are `1` and `2`. Default is `2`. |
| `normalApproximation` | Logical. Whether to use normal approximation in `rpact`. Default is `FALSE`. |
| `alpha` | Significance level. Default is `0.025`. |
| `beta` | Type II error rate. Power is `1 - beta`. Default is `0.2`. |
| `alternative` | Hypothesized mean difference used by the rpact calculation. |
| `sided` | `1` for one-sided test, `2` for two-sided test. |
| `stDev` | Common standard deviation. Must be positive. |
| `allocationRatioPlanned` | Planned allocation ratio. Default is `1`. |
| `singlearmsamplesize` | Per-group sample size used by the formula-based MDD calculation. |
| `digits` | Number of decimal places in the output. |

## Example

``` r
res_cont <- ps_continuous_two_arm(
  alpha = 0.025,
  beta = 0.2,
  alternative = 4.023819,
  sided = 1,
  stDev = 19,
  allocationRatioPlanned = 1,
  singlearmsamplesize = 300
)

print(res_cont)
```

## Returned object

`ps_continuous_two_arm()` returns an object of class:

``` text
PowStatContinuousTwoArm
```

The returned object contains:

| Field        | Description                                               |
|--------------|-----------------------------------------------------------|
| `parameters` | Study parameters as a data frame.                         |
| `results`    | Comparison between rpact-based and formula-based results. |

## Output interpretation

The printed output contains:

1.  **Study Parameters**
    - Endpoint type
    - Design type
    - Alpha
    - Beta
    - Power
    - Sidedness
    - Standard deviation
    - Allocation ratio
    - Formula sample size
2.  **Main Results**
    - Method name
    - Group 1 sample size
    - Group 2 sample size
    - Total sample size
    - Critical effect scale
    - Minimal Detectable Difference

------------------------------------------------------------------------

# 2. Time-to-event endpoint: two-arm logrank design

## Overview

The function `ps_tte_logrank()` calculates design quantities for a
two-arm time-to-event logrank design.

It supports:

- Fixed designs
- Group sequential designs, GSD
- One or more interim analyses
- Information fraction based analysis looks
- Accrual and follow-up based calendar-time planning
- Dropout adjustment through annual dropout rates
- Efficacy boundary calculation using `gsDesign`

The endpoint model assumes exponential survival.

The control-group hazard is calculated from the median survival:

$$
\lambda_C = \frac{\log(2)}{\text{Median Survival}_C}
$$

The treatment-group hazard is:

$$
\lambda_T = \lambda_C \times HR
$$

The treatment-group median survival is therefore:

$$
\text{Median Survival}_T = \frac{\text{Median Survival}_C}{HR}
$$

The required number of events is based on the Schoenfeld approximation:

$$
D = \frac{(Z_{\alpha} + Z_{\beta})^2}
{p_T(1 - p_T)\log(HR)^2}
$$

where $p_T$ is the treatment allocation proportion.

For allocation ratio $r = n_T/n_C$:

$$
p_T = \frac{r}{1 + r}
$$

## Function signature

``` r
ps_tte_logrank(
  medsurv_control,
  hr,
  n_interim = 0,
  info_frac = NULL,
  alpha = 0.025,
  beta = 0.1,
  allocation_ratio = 1,
  accrual_rate = NULL,
  accrual_duration = NULL,
  n_total = NULL,
  total_study_duration = NULL,
  dropout_rate_control = 0,
  dropout_rate_treatment = dropout_rate_control,
  spending_function = "sfLDOF",
  sided = 1,
  digits = 6
)
```

## Arguments

| Argument | Description |
|----|----|
| `medsurv_control` | Median survival in the control group, measured in months. |
| `hr` | Hazard ratio, treatment/control. Must be positive and not equal to `1`. |
| `n_interim` | Number of interim analyses. Use `0` for a fixed design. |
| `info_frac` | Information fractions for interim analyses. If omitted, default fractions are generated. |
| `alpha` | Significance level. Default is `0.025`. |
| `beta` | Type II error rate. Default is `0.1`. |
| `allocation_ratio` | Treatment/control allocation ratio. Default is `1`. |
| `accrual_rate` | Accrual rate per month. Used in Mode 1 or Mode 2. |
| `accrual_duration` | Accrual duration in months. Used in Mode 1 or Mode 3. |
| `n_total` | Total sample size. Used in Mode 2. |
| `total_study_duration` | Total study duration in months. Used in Mode 3. |
| `dropout_rate_control` | Annual dropout rate in the control group. Default is `0`. |
| `dropout_rate_treatment` | Annual dropout rate in the treatment group. Defaults to control dropout rate. |
| `spending_function` | Spending function name. Default is `"sfLDOF"`. |
| `sided` | `1` for one-sided test, `2` for two-sided test. |
| `digits` | Number of decimal places in printed output. |

## Input modes

`ps_tte_logrank()` supports three input modes.

### Mode 1: accrual rate plus accrual duration

Use this mode when the accrual rate and accrual duration are known.

``` text
accrual_rate + accrual_duration -> solve total N and follow-up duration
```

Example:

``` r
res_tte_mode1 <- ps_tte_logrank(
  medsurv_control = 9.7,
  hr = 0.692,
  n_interim = 0,
  alpha = 0.025,
  beta = 0.15,
  accrual_rate = 20,
  accrual_duration = 21.5,
  dropout_rate_control = 0.10
)

print(res_tte_mode1)
```

### Mode 2: accrual rate plus total sample size

Use this mode when the accrual rate and total sample size are known.

``` text
accrual_rate + n_total -> solve accrual duration and follow-up duration
```

Example:

``` r
res_tte_mode2 <- ps_tte_logrank(
  medsurv_control = 9.7,
  hr = 0.692,
  n_interim = 0,
  alpha = 0.025,
  beta = 0.15,
  accrual_rate = 20,
  n_total = 430,
  dropout_rate_control = 0.10
)

print(res_tte_mode2)
```

### Mode 3: accrual duration plus total study duration

Use this mode when the accrual duration and total study duration are
known.

``` text
accrual_duration + total_study_duration -> solve sample size
```

Example:

``` r
res_tte_mode3 <- ps_tte_logrank(
  medsurv_control = 9.7,
  hr = 0.692,
  n_interim = 0,
  alpha = 0.025,
  beta = 0.15,
  accrual_duration = 21.5,
  total_study_duration = 36,
  dropout_rate_control = 0.10
)

print(res_tte_mode3)
```

## Fixed design example

``` r
res_tte_fixed <- ps_tte_logrank(
  medsurv_control = 9.7,
  hr = 0.692,
  n_interim = 0,
  alpha = 0.025,
  beta = 0.15,
  accrual_rate = 20,
  accrual_duration = 21.5,
  dropout_rate_control = 0.10
)

print(res_tte_fixed)
```

## Group sequential design example

The following example specifies one interim analysis at 70% information.

``` r
res_tte_gsd <- ps_tte_logrank(
  medsurv_control = 9.7,
  hr = 0.692,
  n_interim = 1,
  info_frac = 0.7,
  alpha = 0.025,
  beta = 0.15,
  accrual_rate = 20,
  accrual_duration = 21.75,
  dropout_rate_control = 0.10,
  spending_function = "sfLDOF"
)

print(res_tte_gsd)
```

## Returned object

`ps_tte_logrank()` returns an object of class:

``` text
PowStatTTELogrank
```

The returned object contains:

| Field | Description |
|----|----|
| `input` | Study input parameters. |
| `model_summary` | Survival and dropout model summary. |
| `sample_size_summary` | Sample size by treatment group and total sample size. |
| `event_summary` | Event target and information summary. |
| `duration_summary` | Accrual and study duration summary. |
| `stages` | Analysis-look details, including boundaries and MDD. |
| `digits` | Number of decimal places for printing. |

## Output interpretation

The printed output contains the following sections.

### Study Parameters

Includes:

- Endpoint
- Design type
- Input mode
- Hypothesis
- Number of interim analyses
- Alpha
- Beta
- Power
- Allocation ratio
- Median survival values
- Hazard ratio
- Accrual rate
- Accrual duration
- Total sample size
- Dropout rates
- Spending function

### Survival and Dropout Model

Includes:

- Control hazard
- Treatment hazard
- Hazard ratio
- Control median survival
- Treatment median survival
- Annual dropout rates

### Sample Size Information

Includes:

- Treatment sample size
- Control sample size
- Total sample size

### Event and Information Summary

Includes:

- Fixed-design event target
- Rounded fixed-design event target
- Fixed-design power
- Information inflation
- Final event target
- Final cumulative power under H1
- Final cumulative alpha under H0
- Final MDD

### Accrual and Study Duration Summary

Includes:

- Accrual duration
- Additional follow-up
- Total study duration
- Average event probability
- Expected final events
- Feasibility indicator

### Analysis-Look Details

Includes:

- Analysis look
- Interim/final label
- Information fraction
- Cumulative rounded events
- Calendar time
- Additional follow-up
- Efficacy boundary Z value
- Efficacy boundary p value
- Stagewise positive probability under H1
- Cumulative positive probability under H1
- Stagewise false-positive probability under H0
- Cumulative false-positive probability under H0
- Minimum detectable hazard ratio, MDD

------------------------------------------------------------------------

# 3. Binary endpoint: two-arm superiority design

## Overview

The function `ps_binary_two_arm()` calculates sample size and critical
effect scale for a two-arm superiority design with a binary endpoint.

It compares three methods:

1.  **Z pooled**
    - Uses `rpact::getSampleSizeRates()` for the primary sample size
      calculation.
    - Also reports a manually calculated pooled critical value.
2.  **Z unpooled**
    - Uses an unpooled Wald approximation.
    - Calculates the sample size manually.
3.  **Exact Fisher**
    - Searches over control-group sample size.
    - Uses Fisher’s exact test by enumeration.
    - Stops at the first sample size meeting the target power.

The superiority alternative assumes:

$$
p_1 > p_0
$$

where:

- $p_0$ is the control-group response rate.
- $p_1$ is the treatment-group response rate.

The risk difference is:

$$
\Delta = p_1 - p_0
$$

## Function signature

``` r
ps_binary_two_arm(
  p0,
  p1,
  sided = 1,
  allocationRatioPlanned = 1,
  alpha = 0.025,
  beta = 0.01,
  n_fixed = NULL,
  exact_max_n0 = 5000,
  digits = 6
)
```

## Arguments

| Argument | Description |
|----|----|
| `p0` | Control-group response rate. Must be between `0` and `1`. |
| `p1` | Treatment-group response rate. Must be between `0` and `1`, and greater than `p0`. |
| `sided` | `1` for one-sided test, `2` for two-sided test. |
| `allocationRatioPlanned` | Planned treatment/control allocation ratio. Default is `1`. |
| `alpha` | Significance level. Default is `0.025`. |
| `beta` | Type II error rate. Default is `0.01`. |
| `n_fixed` | Optional fixed total sample size, or a two-element vector giving group sizes. |
| `exact_max_n0` | Maximum control-group sample size for Fisher exact search. |
| `digits` | Number of decimal places in printed output. |

## Example

``` r
res_bin_two <- ps_binary_two_arm(
  p0 = 0.1,
  p1 = 0.4,
  sided = 1,
  alpha = 0.025,
  beta = 0.15,
  allocationRatioPlanned = 1,
  n_fixed = 72
)

print(res_bin_two)
```

## Example with unequal allocation

``` r
res_bin_two_unequal <- ps_binary_two_arm(
  p0 = 0.1,
  p1 = 0.4,
  sided = 1,
  alpha = 0.025,
  beta = 0.15,
  allocationRatioPlanned = 2,
  n_fixed = 90
)

print(res_bin_two_unequal)
```

## Returned object

`ps_binary_two_arm()` returns an object of class:

``` text
PowStatBinaryTwoArm
```

The returned object contains:

| Field | Description |
|----|----|
| `input` | Study input parameters. |
| `sample_size_summary` | Summary of Z pooled, Z unpooled, and Fisher exact methods. |
| `fixed_n_criticalValuesEffectScale` | Fixed sample size evaluation, if `n_fixed` is provided. |

## Output interpretation

The printed output contains:

1.  **Study Parameters**
    - Endpoint type
    - Design
    - `p0`
    - `p1`
    - Risk difference
    - Sidedness
    - Alpha
    - Beta
    - Power
    - Allocation ratio
    - Fixed sample size
    - Exact Fisher search limit
2.  **Sample Size and Critical Effect Scale Summary**
    - Method source
    - Method name
    - Treatment sample size `n1`
    - Control sample size `n0`
    - Total sample size
    - Achieved power
    - rpact critical value, where applicable
    - Manual pooled critical value
    - Manual unpooled critical value
3.  **Fixed Sample Size Evaluation**
    - Reported only when `n_fixed` is provided.
    - Includes fixed group sizes, total sample size, achieved power, and
      critical values.

## Notes on exact Fisher calculation

The Fisher exact method enumerates all possible event-count pairs:

$$
X_1 = 0, 1, ..., n_1
$$

$$
X_0 = 0, 1, ..., n_0
$$

For each pair, Fisher’s exact test is performed. The exact power is the
sum of probabilities of all rejection-region outcomes under the assumed
true response rates $p_1$ and $p_0$.

Because enumeration can be computationally expensive, `exact_max_n0`
controls the maximum control-group sample size searched.

------------------------------------------------------------------------

# 4. Binary endpoint: single-arm exact binomial design

## Overview

The function `ps_binary_single_arm()` calculates sample size, critical
point, attained alpha, and power for a single-arm exact binomial test.

It supports two one-sided alternatives:

1.  `"greater"`
    - Used when the target is to show that the true response rate is
      greater than the null response rate.
    - Rejection region:

$$
X \ge r
$$

2.  `"less"`
    - Used when the target is to show that the true response rate is
      less than the null response rate.
    - Rejection region:

$$
X \le r
$$

For the `"greater"` alternative:

$$
\alpha_{\text{attained}} = P(X \ge r \mid p = p_0)
$$

$$
\text{Power} = P(X \ge r \mid p = p_1)
$$

For the `"less"` alternative:

$$
\alpha_{\text{attained}} = P(X \le r \mid p = p_0)
$$

$$
\text{Power} = P(X \le r \mid p = p_1)
$$

## Function signature

``` r
ps_binary_single_arm(
  p0,
  p1,
  alpha = 0.025,
  power_target = 0.90,
  n_min = 1,
  n_max = 200,
  alternative = "greater",
  n_fixed = NULL,
  power_curve = TRUE,
  p_seq = seq(0.01, 0.99, by = 0.01),
  plot = TRUE,
  digits = 4,
  ci_level = 0.95
)
```

## Arguments

| Argument | Description |
|----|----|
| `p0` | Null hypothesis response rate. Must be between `0` and `1`. |
| `p1` | Alternative hypothesis response rate. Must be between `0` and `1`. |
| `alpha` | Significance level. Default is `0.025`. |
| `power_target` | Target power. Default is `0.90`. |
| `n_min` | Minimum sample size to search. Default is `1`. |
| `n_max` | Maximum sample size to search. Default is `200`. |
| `alternative` | `"greater"` or `"less"`. |
| `n_fixed` | Optional fixed sample size to evaluate. |
| `power_curve` | Logical. Whether to compute power curve data. |
| `p_seq` | Sequence of true response rates used for the power curve. |
| `plot` | Logical. Whether to build a client-side `ggplot2` power curve. |
| `digits` | Number of decimal places in printed output. |
| `ci_level` | Confidence interval level for the Clopper-Pearson exact CI. |

## Example: greater alternative

``` r
res_bin_single <- ps_binary_single_arm(
  p0 = 0.1,
  p1 = 0.3,
  alpha = 0.025,
  power_target = 0.90,
  n_min = 1,
  n_max = 200,
  alternative = "greater",
  n_fixed = 41,
  power_curve = TRUE,
  plot = TRUE
)

print(res_bin_single)
```

If `ggplot2` is installed and `plot = TRUE`, a plot object is stored in:

``` r
res_bin_single$plot
```

You can display it by running:

``` r
res_bin_single$plot
```

## Example: less alternative

``` r
res_bin_single_less <- ps_binary_single_arm(
  p0 = 0.4,
  p1 = 0.2,
  alpha = 0.025,
  power_target = 0.90,
  n_min = 1,
  n_max = 200,
  alternative = "less",
  n_fixed = 50,
  power_curve = TRUE,
  plot = TRUE
)

print(res_bin_single_less)
```

## Returned object

`ps_binary_single_arm()` returns an object of class:

``` text
PowStatBinarySingleArm
```

The returned object contains:

| Field | Description |
|----|----|
| `input` | Study input parameters. |
| `design_summary` | Summary of the optimal and fixed designs. |
| `optimal_design` | Smallest sample size satisfying the target power. |
| `fixed_design` | Fixed sample size design, if `n_fixed` is provided. |
| `valid_designs` | All designs within the search range satisfying target power. |
| `power_curve` | Power curve data, if requested. |
| `plot` | Optional `ggplot2` object for the power curve. |
| `input_raw` | Raw input parameter list used by the client. |

## Showing all valid designs

By default, the print method shows the primary design summary only.

To print all valid designs satisfying the target power:

``` r
print(res_bin_single, show_valid = TRUE)
```

## Power curve

If `power_curve = TRUE`, the server returns a data frame containing
power across the grid of true response rates specified by `p_seq`.

Example:

``` r
head(res_bin_single$power_curve)
```

If `plot = TRUE`, the client attempts to create a `ggplot2` object with:

- A power curve line.
- A horizontal line at the target power.
- A vertical line at `p0`.
- A vertical line at `p1`.

The plot is generated client-side. The server does not generate plots.

------------------------------------------------------------------------

# Input validation

The client and server both perform input validation.

This double-validation pattern helps ensure that:

1.  Common input issues are caught early on the client side.
2.  The server engine remains protected even if called directly.
3.  API requests are less likely to trigger unclear calculation errors.

## Common validation rules

### Continuous two-arm design

| Parameter                | Rule                           |
|--------------------------|--------------------------------|
| `groups`                 | Must be `1` or `2`.            |
| `alpha`                  | Must be between `0` and `1`.   |
| `beta`                   | Must be between `0` and `1`.   |
| `sided`                  | Must be `1` or `2`.            |
| `stDev`                  | Must be positive.              |
| `allocationRatioPlanned` | Must be positive.              |
| `singlearmsamplesize`    | Must be provided and positive. |
| `alternative`            | Must be provided.              |

### Time-to-event logrank design

| Parameter         | Rule                                        |
|-------------------|---------------------------------------------|
| `medsurv_control` | Must be positive.                           |
| `hr`              | Must be positive and not equal to `1`.      |
| `alpha`           | Must be between `0` and `1`.                |
| `beta`            | Must be between `0` and `1`.                |
| `sided`           | Must be `1` or `2`.                         |
| `n_interim`       | Must be non-negative.                       |
| Input mode        | Must be exactly one of the supported modes. |

### Binary two-arm design

| Parameter | Rule                         |
|-----------|------------------------------|
| `p0`      | Must be between `0` and `1`. |
| `p1`      | Must be between `0` and `1`. |
| `p1`      | Must be greater than `p0`.   |
| `alpha`   | Must be between `0` and `1`. |
| `beta`    | Must be between `0` and `1`. |
| `sided`   | Must be `1` or `2`.          |

### Binary single-arm design

| Parameter      | Rule                             |
|----------------|----------------------------------|
| `p0`           | Must be between `0` and `1`.     |
| `p1`           | Must be between `0` and `1`.     |
| `alpha`        | Must be between `0` and `1`.     |
| `power_target` | Must be between `0` and `1`.     |
| `alternative`  | Must be `"greater"` or `"less"`. |

------------------------------------------------------------------------

# Returned S3 classes and print methods

Each main function returns a named list with a custom S3 class.

| Function | S3 class | Print method |
|----|----|----|
| `ps_continuous_two_arm()` | `PowStatContinuousTwoArm` | `print.PowStatContinuousTwoArm()` |
| `ps_tte_logrank()` | `PowStatTTELogrank` | `print.PowStatTTELogrank()` |
| `ps_binary_two_arm()` | `PowStatBinaryTwoArm` | `print.PowStatBinaryTwoArm()` |
| `ps_binary_single_arm()` | `PowStatBinarySingleArm` | `print.PowStatBinarySingleArm()` |

The S3 print methods are designed to provide readable summaries for
clinical trial planning workflows.

You can also access the raw result fields directly.

Example:

``` r
res_bin_single$input
res_bin_single$design_summary
res_bin_single$optimal_design
res_bin_single$power_curve
```

------------------------------------------------------------------------

# Dependencies

## Client-side dependencies

The client-side package may require:

- Base R
- `jsonlite` or equivalent, depending on the implementation of
  `powstat_api_call()`
- `httr`, `httr2`, or equivalent HTTP client package
- `ggplot2`, optional, for binary single-arm power curve plotting

The plotting helper `.build_power_curve_plot()` checks for `ggplot2`
with:

``` r
requireNamespace("ggplot2", quietly = TRUE)
```

If `ggplot2` is not installed, the function returns `NULL` for the plot
object.

# Detailed methodological notes

## Continuous endpoint MDD

For the formula-based approach, the standard error for a two-arm
comparison is:

$$
SE = SD \times \sqrt{\frac{1}{n_1} + \frac{1}{n_2}}
$$

The critical effect scale is:

$$
Z_{\alpha} \times SE
$$

The MDD is:

$$
(Z_{\alpha} + Z_{\beta}) \times SE
$$

If `groups = 1`, the single-arm standard error is:

$$
SE = \frac{SD}{\sqrt{n}}
$$

## Time-to-event event probability under uniform accrual

The time-to-event engine computes event probability under uniform
accrual and exponential survival/dropout.

For a given event hazard $\lambda_E$, dropout hazard $\lambda_D$,
accrual duration $A$, and additional follow-up $F$, the combined hazard
is:

$$
\lambda = \lambda_E + \lambda_D
$$

The event probability is:

$$
P(\text{event}) =
\frac{\lambda_E}{\lambda}
\left[
1 -
\exp(-\lambda F)
\frac{1 - \exp(-\lambda A)}{\lambda A}
\right]
$$

when $A > 0$.

When $A \le 0$, the event probability is:

$$
P(\text{event}) =
\frac{\lambda_E}{\lambda}
\left[
1 - \exp(-\lambda F)
\right]
$$

The annual dropout rate is converted to a monthly dropout hazard using:

$$
\lambda_D = -\frac{\log(1 - d)}{12}
$$

where $d$ is the annual dropout rate.

## Group sequential design

For group sequential designs, `compute_tte_logrank()` calls:

``` r
gsDesign::gsDesign(
  k = n_interim + 1,
  test.type = ifelse(sided == 2, 2, 1),
  alpha = alpha,
  beta = beta,
  timing = info_frac,
  sfu = spending_function
)
```

The information inflation factor is:

$$
\frac{n.I_k}{n.fix}
$$

The final event target is the fixed-design event target multiplied by
this inflation factor.

The stagewise event targets are calculated from the information
fractions and rounded upward.

## Time-to-event MDD

For each analysis look, the minimum detectable hazard ratio is
calculated as:

$$
MDD = \exp \left(
  -Z \sqrt{
    \frac{1}{D \times p_T(1 - p_T)}
  }
\right)
$$

where:

- $Z$ is the efficacy boundary at the analysis look.
- $D$ is the cumulative event count at that look.
- $p_T$ is the treatment allocation proportion.

## Binary two-arm Z unpooled sample size

For the unpooled Wald approximation, the control-group sample size is
calculated as:

$$
n_0 =
\left\lceil
\frac{
  (Z_{\alpha} + Z_{\beta})^2
  \left[
    \frac{p_1(1 - p_1)}{r} + p_0(1 - p_0)
  \right]
}{
  (p_1 - p_0)^2
}
\right\rceil
$$

where $r = n_1/n_0$.

Then:

$$
n_1 = \lceil r n_0 \rceil
$$

## Binary single-arm exact binomial

For each candidate sample size $n$, the server searches for a critical
point $r$.

For the `"greater"` alternative, it searches from $r = 0$ to $n$ and
selects the first $r$ satisfying:

$$
P(X \ge r \mid p_0) \le \alpha
$$

For the `"less"` alternative, it searches from $r = n$ to $0$ and
selects the first $r$ satisfying:

$$
P(X \le r \mid p_0) \le \alpha
$$

The smallest sample size meeting the target power is reported as the
optimal design.

------------------------------------------------------------------------

# Example workflow

The following example shows a typical analysis workflow.

``` r
library(PowStat)

# 1. Binary single-arm design
single_arm <- ps_binary_single_arm(
  p0 = 0.1,
  p1 = 0.3,
  alpha = 0.025,
  power_target = 0.90,
  n_fixed = 41,
  plot = TRUE
)

print(single_arm)

# 2. Binary two-arm design
two_arm_binary <- ps_binary_two_arm(
  p0 = 0.1,
  p1 = 0.4,
  alpha = 0.025,
  beta = 0.15,
  allocationRatioPlanned = 1,
  n_fixed = 72
)

print(two_arm_binary)

# 3. Continuous two-arm MDD
continuous <- ps_continuous_two_arm(
  alpha = 0.025,
  beta = 0.2,
  alternative = 4.023819,
  sided = 1,
  stDev = 19,
  allocationRatioPlanned = 1,
  singlearmsamplesize = 300
)

print(continuous)

# 4. Time-to-event logrank design
tte <- ps_tte_logrank(
  medsurv_control = 9.7,
  hr = 0.692,
  n_interim = 1,
  info_frac = 0.7,
  alpha = 0.025,
  beta = 0.15,
  accrual_rate = 20,
  accrual_duration = 21.75,
  dropout_rate_control = 0.10
)

print(tte)
```

------------------------------------------------------------------------

# Citation

If you use `PowStat` in a report, protocol, SAP, or publication, please
cite the package and the statistical methods or R packages used by the
corresponding module.

For example:

- `rpact` package for confirmatory adaptive clinical trial design
  methods.
- `gsDesign` package for group sequential design calculations.
- Exact binomial methods for single-arm binary endpoint designs.
- Schoenfeld approximation for logrank event calculations.

------------------------------------------------------------------------

# License

Please specify the license for this package in the `LICENSE` file.

``` text
GPL-3
```

------------------------------------------------------------------------

# Contact

For issues, feature requests, or bug reports, please open an issue on
GitHub:

<a href="https://github.com/YOUR-ORG/PowStat/issues"
class="uri">https://github.com/chenchaostat/PowStat/issues</a>.

You can also contact me via email at <chenchaostat@163.com>.
