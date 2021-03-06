library(ganalytics)

context("Selecting a dimension and metric variable")

test_that("GaVar generates a .gaVar object of the appropriate subclass", {
  expect_is(GaVar("ga:source"), "gaDimVar")
  expect_is(GaVar("ga:pageviews"), "gaMetVar")
  expect_is(GaVar("dateOfSession"), "gaDimVar")
  expect_error(GaVar("NotAVariable"))
})

test_that("Initialisation of a .gaVar object corrects the variable name", {
  expect_identical(GaVar("medium"), GaVar("ga:medium"))
  expect_identical(GaVar("pagepath"), GaVar("ga:pagePath"))
  expect_identical(GaVar("landingpage"), GaVar("ga:landingPagePath"))
  expect_identical(GaVar("dateofsess"), GaVar("dateOfSession"))
  expect_identical(GaVar("completionsall"), GaVar("ga:goalCompletionsAll"))
})

context("Forming a basic condition expression")

test_that("GaExpr generates a .gaExpr object of the appropriate subclass", {
  expect_is(GaExpr("pageviews", ">", "2"), "gaMetExpr")
  expect_is(GaExpr("campaign", "=~", "(not set)"), "gaDimExpr")
  expect_is(GaExpr("pagetitle", "~", "products"), "gaDimExpr")
  expect_is(GaExpr("hostname", "!", "google.com"), "gaDimExpr")
  expect_is(GaExpr("totalevents", "=>", 5), "gaMetExpr")
  expect_error(GaExpr("entrances", "=@", "23"))
  expect_error(GaExpr("pageviews", "+", 2))
})

test_that(".gaExpr objects coerce to character", {
  expect_equal(as(
    GaExpr("eventcategory", "~=", "^video"),
    "character"), "ga:eventCategory=~^video")
  expect_equal(as(
    GaExpr("ga:uniquePageviews", ">", 5),
    "character"), "ga:uniquePageviews>5")
  expect_equal(as(
    GaExpr("pagePath", "~", "[;,\\-].+"),
    "character"), "ga:pagePath=~[\\;\\,\\\\-].+")
})

test_that("GaNot can be used to invert an expression", {
  expect_identical(
    GaNot(GaExpr("pageviews", ">", 10)),
    GaExpr("pageviews", "<=", 10)
  )
  expect_identical(
    !(GaExpr("pageviews", ">", 10)),
    GaExpr("pageviews", "<=", 10)
  )
  expect_error(!Expr("eventCategory", "[]", c("video", "download")), "cannot be NOTed")
})

context("Combining basic condition expressions with AND and OR")

test_that("Expressions can be ORed to give the correct character output", {
  expect_equal(as(
    GaOr(
      GaExpr("pageviews", ">", 100),
      GaExpr("timeOnPage", "<", 2000)
    ),
    "character"), "ga:pageviews>100,ga:timeOnPage<2000")
  expect_equal(as(
    GaOr(
      GaExpr("pageviews", ">", 100),
      GaExpr("timeOnPage", "<", 2000),
      GaExpr("bounceRate", "=", 100)
    ),
    "character"), "ga:pageviews>100,ga:timeOnPage<2000,ga:bounceRate==100")
  expect_equal(as(
    GaExpr("pageviews", ">", 100) |
    GaExpr("timeOnPage", "<", 2000),
    "character"), "ga:pageviews>100,ga:timeOnPage<2000")
  expect_equal(as(
    GaExpr("pageviews", ">", 100) |
    (GaExpr("timeOnPage", "<", 2000) |
    GaExpr("bounceRate", "=", 100)),
    "character"), "ga:pageviews>100,ga:timeOnPage<2000,ga:bounceRate==100")
})

test_that("Expressions can be ANDed to give the correct character output", {
  expect_equal(as(
    GaAnd(
      GaExpr("pageviews", ">", 100),
      GaExpr("timeOnPage", "<", 2000)
    ),
    "character"), "ga:pageviews>100;ga:timeOnPage<2000")
  expect_equal(as(
    GaAnd(
      GaExpr("pageviews", ">", 100),
      GaExpr("timeOnPage", "<", 2000),
      GaExpr("bounceRate", "=", 100)
    ),
    "character"), "ga:pageviews>100;ga:timeOnPage<2000;ga:bounceRate==100")
  expect_equal(as(
    GaExpr("pageviews", ">", 100) &
    GaExpr("timeOnPage", "<", 2000),
    "character"), "ga:pageviews>100;ga:timeOnPage<2000")
  expect_equal(as(
    GaExpr("pageviews", ">", 100) &
    (GaExpr("timeOnPage", "<", 2000) &
    GaExpr("bounceRate", "=", 100)),
    "character"), "ga:pageviews>100;ga:timeOnPage<2000;ga:bounceRate==100")
})

test_that("ORed expressions can be ANDed, but ANDed expressions cannot be ORed", {
  expect_equal(as(
    GaAnd(
      GaOr(
        GaExpr("eventValue", "<", 50),
        GaExpr("keyword", "@", "contact")
      ),
      GaExpr("deviceCategory", "=", "mobile")
    ),
    "character"), "ga:eventValue<50,ga:keyword=@contact;ga:deviceCategory==mobile")
  expect_equal(as(
    (
      GaExpr("eventValue", "<", 50) |
      GaExpr("keyword", "@", "contact")
    ) & GaExpr("deviceCategory", "=", "mobile"),
    "character"), "ga:eventValue<50,ga:keyword=@contact;ga:deviceCategory==mobile")
  expect_error(
    GaOr(
      GaAnd(
        GaExpr("eventValue", "<", 50),
        GaExpr("keyword", "@", "contact")
      ),
      GaExpr("deviceCategory", "=", "mobile")
    ),
    "ANDed expressions cannot be ORed"
  )
  expect_error(
    GaExpr("eventValue", "<", 50) &
    GaExpr("keyword", "@", "contact") |
    GaExpr("deviceCategory", "=", "mobile")
  )
  expect_equal(as(
    GaOr(
      GaAnd(
        GaExpr("eventValue", "<", 50),
        GaExpr("keyword", "@", "contact")
      )
    ),
  "character"), "ga:eventValue<50,ga:keyword=@contact")
  expect_equal(as(
    GaAnd(
      GaOr(
        GaExpr("eventValue", "<", 50),
        GaExpr("keyword", "@", "contact")
      ),
      GaAnd(
        GaExpr("deviceCategory", "=", "mobile"),
        GaAnd(
          GaExpr("pageviews", ">", 100),
          GaExpr("timeOnPage", "<", 2000),
          GaExpr("bounceRate", "=", 100)
        )
      )
    ),
    "character"), "ga:eventValue<50,ga:keyword=@contact;ga:deviceCategory==mobile;ga:pageviews>100;ga:timeOnPage<2000;ga:bounceRate==100")
})

test_that("ORed expressions can be NOTed", {
  expect_identical(
    GaNot(GaOr(GaExpr("source", "=", "google"), GaExpr("medium", "=", "organic"))),
    GaAnd(GaExpr("source", "!=", "google"), GaExpr("medium", "!=", "organic"))
  )
  expect_identical(
    !(GaExpr("source", "=", "google") | GaExpr("medium", "=", "organic")),
    GaExpr("source", "!=", "google") & GaExpr("medium", "!=", "organic")
  )
})

context("Using expressions to create filters")

test_that("a filter can be a basic expression", {
  expect_is(
    GaFilter(GaExpr("dimension1", "!", "yellow")),
    "gaFilter"
  )
  expect_equal(
    as(GaFilter(GaExpr("dimension1", "!", "yellow")), "character"),
    "ga:dimension1!=yellow"
  )
})

test_that("ANDed (but not ORed) filter expressions may mix dimensions with metrics", {
  expect_equal(as(
    GaFilter(GaOr(GaExpr("pageviews", ">", 10), GaExpr("entrances", "<", 5))),
    "character"), "ga:pageviews>10,ga:entrances<5")
  expect_error(
    GaFilter(GaOr(GaExpr("landingPagePath", "=", "/"), GaExpr("entrances", "<", 5))),
    "cannot mix metrics and dimensions"
  )
  expect_equal(as(
    GaFilter(GaAnd(GaExpr("landingPagePath", "=", "/"), GaExpr("entrances", "<", 5))),
    "character"), "ga:landingPagePath==/;ga:entrances<5")
  expect_error(
    GaFilter(
      GaAnd(
        GaOr(
          GaExpr("eventValue", "<", 50),
          GaExpr("keyword", "@", "contact")
        ),
        GaExpr("deviceCategory", "=", "mobile")
      )
    )
  )
})

test_that("Filter expressions cannot use '[]' or '<>' operators", {
  expect_error(
    GaFilter(GaExpr("medium", "[]", c("organic", "cpc"))),
    "\\[\\]"
  )
  expect_error(
    GaFilter(GaExpr("pageviews", "<>", c(10, 100))),
    "<>"
  )
})

context("Correct formatting of operators and operands used in API queries")

test_that("expressions for each type of operator are correctly formatted when coerced to character", {
  expect_equal(as(
    GaExpr("dateOfSession", "<>", c("2015-01-01", "2015-01-15")),
    "character"), "dateOfSession<>2015-01-01_2015-01-15")
  expect_equal(as(
    GaExpr("daysSinceLastSession", "<>", c(1, 5)),
    "character"), "ga:daysSinceLastSession<>1_5")
  expect_equal(as(
    GaExpr("pageviews", "<>", c(10, 50)),
    "character"), "ga:pageviews<>10_50")
  expect_error(GaExpr("pageviews", "<>", c(50, 10))) # Second value must be greater than first
  expect_equal(as(
    GaExpr("source", "[]", c("google", "email", "youtube")),
    "character"), "ga:source[]google|email|youtube")
  expect_error(GaExpr("source", "==", c("google", "email", "youtube")))
  expect_error(GaExpr("pageviews", "!=", c(1, 2)))
})

test_that("expressions operands are corrected depending on the type of dimension and operator", {
  expect_equal(as(
    GaExpr("date", "!=", "2014-01-01"),
    "character"), "ga:date!=20140101")
  expect_equal(as(
    GaExpr("date", "!=", "20140101"),
    "character"), "ga:date!=20140101")
  expect_equal(as(
    GaExpr("istablet", "=", TRUE),
    "character"), "ga:isTablet==Yes")
  expect_equal(as(
    GaExpr("istablet", "=", "no"),
    "character"), "ga:isTablet==No")
  expect_error(Expr("istablet", "==", "maybe"), "invalid .* operand")
  expect_equal(as(
    GaExpr("usertype", "=", "returning"),
    "character"), "ga:userType==Returning Visitor")
})

context("Segmentation queries are correctly formatted for API requests")

test_that("segment expressions are correctly coerced to character string", {
  expect_equal(
    as(
      GaSegment(
        GaSegmentCondition(
          GaNonSequenceCondition(GaExpr("source", "=", "google")),
          GaSequenceCondition(
            GaStartsWith(GaExpr("pagepath", "=", "/")),
            GaImmediatelyPrecedes(GaExpr("pagepath", "=", "/products/")),
            GaPrecedes(GaExpr("exitPage", "=", "/"))
          ),
          scope = "sessions"
        ),
        GaSegmentCondition(
          GaNonSequenceCondition(GaExpr("deviceCategory", "=", "mobile")),
          scope = "users"
        )
      ),
      "character"),
    "sessions::condition::ga:source==google;sequence::^ga:pagePath==/;->ga:pagePath==/products/;->>ga:exitPagePath==/;users::condition::ga:deviceCategory==mobile")
})

test_that("segment expressions can be negated", {
  expect_equal(as(
    GaNonSequenceCondition(
      GaExpr("source", "=", "google"),
      negation = TRUE
    ),
    "character"), "condition::!ga:source==google")
  expect_identical(
    GaNonSequenceCondition(
      GaExpr("source", "=", "google"),
      negation = TRUE
    ),
    GaNot(GaNonSequenceCondition(
      GaExpr("source", "=", "google"),
      negation = FALSE
    ))
  )
})

test_that("segments can be selected by ID and parsed", {
  expect_identical(
    GaSegment(-1),
    GaSegment("gaid::-1"),
  )
  expect_identical(
    GaSegment("gaid::1"),
    GaSegment("1")
  )
  expect_equal(
    as(GaSegment("gaid::-1"), "character"),
    "gaid::-1"
  )
  expect_equal(
    as(GaSegment("gaid::1"), "character"),
    "gaid::1"
  )
})

context("Constructing Core Reporting API queries")

test_that("GaStartDate, GaEndDate, and GaDateRange give correct formats for API requests", {
  expect_equal(
    as(GaStartDate("2011-01-01"), "character"),
    "2011-01-01"
  )
  expect_equal(
    as(GaEndDate("2011-01-01"), "character"),
    "2011-01-01"
  )
  expect_equal(
    as(GaStartDate("20110101"), "character"),
    "2011-01-01"
  )
  expect_identical(
    GaDateRange("2011-01-01", "20110131"),
    GaDateRange("20110101", "2011-01-31")
  )
  expect_identical(
    GaDateRange("2011-01-01", "2011-01-31"),
    GaDateRange(as.Date("2011-01-01"), as.Date("2011-01-31"))
  )
})

test_that("Sortby parameter is corrected coerced to character", {
  expect_equal(as(
    GaSortBy(c("+source", "-pageviews", "+ga:hostname")),
    "character"), "ga:source,-ga:pageviews,ga:hostname")
  expect_equal(as(
    GaSortBy(c("-source", "+pageviews", "-ga:hostname")),
    "character"), "-ga:source,ga:pageviews,-ga:hostname")
})

test_that("Query limits are enforced", {
  expect_error(
    GaQuery(view = 0, dimensions = c(
      "source", "medium", "campaign", "adContent", "landingpage", "secondpage", "exitpage", "deviceCategory"
    )),
    "Maximum of 7 dimensions"
  )
  expect_equal(
    length(GaDimensions(GaQuery(view = 0, dimensions = NULL))),
    0
  )
  expect_error(
    GaQuery(view = 0, metrics = c(
      "users", "sessions", "pageviews", "uniquepageviews",
      "sessionDuration", "bounces", "transactions", "items", "transactionrevenue",
      "goalcompletions", "totalevents", "uniqueevents"
    )),
    "Maximum of 10 metrics"
  )
  expect_error(
    GaQuery(view = 0, metrics = NULL)
  )
  expect_error(
    # Sort only by dimensions or metrics values that you have used in the
    # dimensions or metrics parameters. If your request sorts on a field that is
    # not indicated in either the dimensions or metrics parameter, you will
    # receive a error.
    GaQuery(view = 0, metrics = "pageviews", dimensions = "source", sortBy = "campaign")
  )
  # You can filter for a dimension or metric that is not part of your query,
  # provided all dimensions/metrics in the request and the filter are valid
  # combinations.
  expect_identical(
    GaFilter(GaExpr("pageviews", ">", 1)),
    GaFilter(
      GaQuery(view = 0, dimensions = "source", metrics = "sessions",
              filters = GaExpr("pageviews", ">", 1))
    )
  )
})

test_that("Queries are constructed correctly for API requests", {
  expect_equal(
    as(
      GaQuery(view = 0, startDate = "2015-01-01", endDate = "2015-01-28",
              metrics = "sessions", dimensions = "deviceCategory", sortBy = "deviceCategory",
              filters = GaExpr("source", "=", "google"), segment = GaExpr("country", "=", "Australia"),
              maxResults = 3, samplingLevel = "HIGHER_PRECISION"),
      "matrix")[,1],
    c(
      ids = "ga:0",
      `start-date` = "2015-01-01",
      `end-date` = "2015-01-28",
      metrics = "ga:sessions",
      dimensions = "ga:deviceCategory",
      sort = "ga:deviceCategory",
      filters = "ga:source==google",
      segment = "sessions::condition::ga:country==Australia",
      samplingLevel = "HIGHER_PRECISION"
    )
  )
})

test_that("providing multiple view IDs, date ranges and multiple segments coerces to a multiple column matrix", {
  expect_equal(
    dim(
      as(
        GaQuery(view = c(0, 1, 2),
                startDate = c("2014-01-01", "2014-01-01"),
                endDate = c("2015-01-01", "2015-01-28"),
                metrics = "sessions", dimensions = "deviceCategory", sortBy = "deviceCategory",
                filters = GaExpr("source", "=", "google"),
                segment = GaExpr("country", "=", "Australia"),
                maxResults = 3, samplingLevel = "HIGHER_PRECISION"),
        "matrix")
    ), c(9, 6)
  )
})

context("MCF and RT expressions, filters, and queries are also supported")

test_that("MCF vars can be generated using McfVar", {
  expect_equal(
    as(McfVar("mcf:totalConversions"), "character"),
    "mcf:totalConversions"
  )
})

test_that("RT vars can be generated using RtVar", {
  expect_equal(
    as(RtVar("rt:activeUsers"), "character"),
    "rt:activeUsers"
  )
})

test_that("MCF and RT expressions can be created with dimensions or metrics", {
  expect_equal(
    as(McfExpr("mcf:totalConversions", ">", 10), "character"),
    "mcf:totalConversions>10"
  )
  expect_equal(
    as(RtExpr("rt:source", "=", "google"), "character"),
    "rt:source==google"
  )
})

test_that("MCF and RT queries can be constructed", {
  expect_equal(
    dim(as(McfQuery(view = 0), "matrix")),
    c(6, 1)
  )
  expect_equal(
    dim(as(RtQuery(view = 0), "matrix")),
    c(3, 1)
  )
})

context("Generalised functions can be used across all types of queries")

test_that("! can be used instead of Not", {
  expect_equal(
    !Expr("rt:activeUsers", "<=", 10),
    Expr("rt:activeUsers", ">", 10)
  )
})

test_that("TableFilter can be used instead of deprecated GaFilter function", {
  expect_is(
    TableFilter(Expr("mcf:totalConversions", ">", 10)),
    "mcfFilter"
  )
})

test_that("Expr function can used to create GA, MCF and RT expressions", {
  expect_equal(
    as(Expr("ga:source", "==", "google"), "character"),
    "ga:source==google"
  )
  expect_equal(
    as(Expr("mcf:source", "==", "google"), "character"),
    "mcf:source==google"
  )
  expect_equal(
    as(Expr("rt:source", "==", "google"), "character"),
    "rt:source==google"
  )
  expect_equal(
    as(
      Expr("mcf:source", "!=", "facebook.com") &
        (
          Expr("mcf:medium", "==", "referral") |
            Expr("mcf:campaignName", "=@", "promo")
          ),
      "character"),
    "mcf:source!=facebook.com;mcf:medium==referral,mcf:campaignName=@promo"
  )
})

test_that("Variable, Operator and Operand compoents of an expression can be extracted" , {
  expect_equal(
    as(Operand(Expr("rt:pagePath", "=~", "^/products/")), "character"),
    "^/products/"
  )
  expect_equal(
    as(Var(Expr("mcf:source", "=~", "\\.au$")), "character"),
    "mcf:source"
  )
  expect_equal(
    as(Operator(Expr("rt:totalEvents", ">", "10")), "character"),
    ">"
  )
})

context("New varList methods work as expected")

test_that("Only valid variable lists can be defined.", {
  expect_is(
    Metrics("ga:sessions", "ga:pageviews", "totalevents"),
    "gaMetrics"
  )
  expect_is(
    Dimensions("mcf:source", "mcf:campaignName", "mcf:medium"),
    "mcfDimensions"
  )
  expect_error(
    Metrics("ga:pageviews", "mcf:totalConversions", "rt:activeUsers")
  )
  expect_is(
    SortBy("rt:activeUsers", "rt:totalEvents", "rt:city"),
    "rtSortBy"
  )
  expect_error(
    SortBy("rt:activeUsers", "ga:totalEvents", "mcf:medium")
  )
})

context("Replace methods work as expected.")

test_that("Operator<- replaces the operator of an expression", {
  expr <- Expr("ga:source", "=", "google.com")
  Operator(expr) <- "=@"
  expect_identical(expr, Expr("ga:source", "=@", "google.com"))
})

test_that("Operand<- replaces the operand of an expression", {
  expr <- Expr("ga:source", "=", "google.com")
  Operand(expr) <- "google.com.au"
  expect_identical(expr, Expr("ga:source", "==", "google.com.au"))
})

test_that("Var<- replaces the variable of an expression", {
  expr <- Expr("ga:source", "=", "google.com")
  Var(expr) <- "rt:source"
  expect_identical(expr, Expr("rt:source", "==", "google.com"))
})

test_that("TableFilter<- replaces the table filter of a query", {
  query <- GaQuery(view = 0)
  table_filter <- TableFilter(
    Expr("ga:source", "=", "google.com") &
    Expr("ga:deviceCategory", "=", "mobile")
  )
  TableFilter(query) <- table_filter
  expect_identical(TableFilter(query), table_filter)
  TableFilter(query) <- NULL
  expect_equivalent(TableFilter(query), TableFilter(NULL))
})

test_that("GaSegment<- replaces the segment of a query", {
  query <- GaQuery(view = 0)
  segment <- 
    Expr("ga:source", "=", "google.com") &
      Expr("ga:deviceCategory", "=", "mobile")
  GaSegment(query) <- segment
  expect_identical(GaSegment(query), GaSegment(segment))
})

test_that("Metrics<-, Dimensions<-, and SortBy<-, work as expected on a query", {
  query <- GaQuery(view = 0)
  Dimensions(query) <- NULL
  expect_equivalent(Dimensions(query), Dimensions(NULL))
  Dimensions(query) <- c("source", "medium")
  expect_identical(Dimensions(query), Dimensions(c("source", "medium")))
  Metrics(query) <- c("pageviews", "sessions")
  expect_equivalent(Metrics(query), Metrics(c("pageviews", "sessions")))
  SortBy(query) <- c("source", "sessions")
  expect_equivalent(SortBy(query), SortBy(c("source", "sessions")))
  SortBy(query) <- NULL
  expect_is(SortBy(query), ".sortBy")
})

test_that("Dimensions or metrics removed from a query are reflected in its sortBy", {
  query <- GaQuery(view = 0)
  Dimensions(query) <- c("eventCategory", "eventAction", "eventLabel")
  Metrics(query) <- c("totalEvents", "uniqueEvents", "eventValue")
  SortBy(query) <- c("totalEvents", "eventValue")
  expect_equivalent(SortBy(query), SortBy("totalEvents", "eventValue"))
  Metrics(query) <- "totalEvents"
  expect_equivalent(SortBy(query), SortBy("totalEvents"))
})

test_that("functions DateRange, StartDate, EndDate, and their replacement versions work across all required signatures", {
  # character dateRange date query
  expect_equivalent(StartDate("2010-01-31"), as.Date("2010-01-31"))
  expect_equivalent(EndDate("20100131"), as.Date("2010-01-31"))
  date_range <- DateRange("2010-01-01", "2010-01-31")
  expect_equivalent(StartDate(date_range), as.Date("2010-01-01"))
  expect_equivalent(EndDate(date_range), as.Date("2010-01-31"))
  EndDate(date_range) <- "2011-01-31"
  expect_equivalent(EndDate(date_range), as.Date("2011-01-31"))
  expect_error(StartDate(date_range) <- "20110201", "cannot be before")
  StartDate(date_range) <- as.Date("2011-01-01")
  expect_equivalent(StartDate(date_range), as.Date("2011-01-01"))
  query <- GaQuery(view = 0)
  DateRange(query) <- date_range
  expect_equivalent(DateRange(query), date_range)
  expect_equivalent(DateRange(date_range), date_range)
  #date_range1 <- DateRange(as.Date("2012-01-01"), as.Date("2012-01-31"))
  #date_range2 <- DateRange("2012-01-01", as.Date("2012-01-31"))
  #date_range3 <- DateRange(as.Date("2012-01-01"), "2012-01-31")
})

test_that("SplitDateRange correctly splits a dateRange object, including that of a .query object", {
  # dateRange
  # query
})

