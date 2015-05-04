#' @include all-classes.R
#' @include init-methods.R
#' @include all-generics.R
#' @include all-coercions.R
#' @include Var.R
#' @include Operator.R
#' @include Operand.R
#' @include ganalytics-package.R
#' @include helper-functions.R
NULL

setMethod("Expr", ".expr", function(.Object) {.Object})

setMethod(
  f = "Expr",
  signature = c("character", "character", "ANY"),
  definition = function(.Object, operator, operand, metricScope) {
    var <- Var(.Object)
    if (is(var, ".gaVar")) {
      GaExpr(.Object, operator, operand, metricScope)
    } else if (is(var, ".mcfVar")) {
      McfExpr(.Object, operator, operand)
    } else if (is(var, ".rtVar")) {
      RtExpr(.Object, operator, operand)
    } else stop("Variable type not recognised for expressions.")
  }
)

setMethod(
  f = "GaExpr",
  signature = c("character", "character", "ANY"),
  definition = function(.Object, operator, operand, metricScope) {
    var <- GaVar(.Object)
    if (class(var) == "gaDimVar") {
      operator <- as(operator, "gaDimOperator")
      operand <- as(operand, "gaDimOperand")
      gaExprClass <- "gaDimExpr"
      new(gaExprClass, var = var, operator = operator, operand = operand)
    } else if (class(var) == "gaMetVar") {
      operator <- as(operator, "gaMetOperator")
      operand <- as(operand, "gaMetOperand")
      if (metricScope != "") {
        gaExprClass <- "gaSegMetExpr"
        new(
          gaExprClass,
          var = var,
          operator = operator,
          operand = operand,
          metricScope = metricScope
        )
      } else {
        gaExprClass <- "gaMetExpr"
        new(gaExprClass, var = var, operator = operator, operand = operand)
      }
    } else {
      stop(paste("Unsupported .gaVar class", class(var), sep = ": "))
    }
  }
)

setMethod(
  f = "McfExpr",
  signature = c("character", "character", "ANY"),
  definition = function(.Object, operator, operand) {
    var <- McfVar(.Object)
    if (class(var) == "mcfDimVar") {
      operator <- as(operator, "mcfDimOperator")
      operand <- as(operand, "mcfDimOperand")
      exprClass <- "mcfDimExpr"
      new(exprClass, var = var, operator = operator, operand = operand)
    } else if (class(var) == "mcfMetVar") {
      operator <- as(operator, "mcfMetOperator")
      operand <- as(operand, "mcfMetOperand")
      exprClass <- "mcfMetExpr"
      new(exprClass, var = var, operator = operator, operand = operand)
    } else {
      stop(paste("Unsupported .mcfVar class", class(var), sep = ": "))
    }
  }
)

setMethod(
  f = "RtExpr",
  signature = c("character", "character", "ANY"),
  definition = function(.Object, operator, operand) {
    var <- RtVar(.Object)
    if (class(var) == "rtDimVar") {
      operator <- as(operator, "rtDimOperator")
      operand <- as(operand, "rtDimOperand")
      exprClass <- "rtDimExpr"
      new(exprClass, var = var, operator = operator, operand = operand)
    } else if (class(var) == "rtMetVar") {
      operator <- as(operator, "rtMetOperator")
      operand <- as(operand, "rtMetOperand")
      exprClass <- "rtMetExpr"
      new(exprClass, var = var, operator = operator, operand = operand)
    } else {
      stop(paste("Unsupported .rtVar class", class(var), sep = ": "))
    }
  }
)

# ---- GaScopeLevel, GaScopeLevel<- ----

setMethod("GaScopeLevel", "gaSegMetExpr", function(.Object) {.Object@metricScope})

setMethod(
  f = "GaScopeLevel<-",
  signature = c("gaSegMetExpr", "character"),
  definition = function(.Object, value) {
    .Object@metricScope <- value
    validObject(.Object)
    .Object
  }
)

setMethod(
  f = "GaScopeLevel<-",
  signature = c("gaMetExpr", "character"),
  definition = function(.Object, value) {
    .Object <- as(.Object, "gaSegMetScope")
    .Object@metricScope <- value
    validObject(.Object)
    .Object
  }
)

setMethod(
  f = "GaScopeLevel",
  signature = "gaSegmentCondition",
  definition = function(.Object) {
    .Object@conditionScope
  }
)

setMethod(
  f = "GaScopeLevel<-",
  signature = c("gaSegmentCondition", "character"),
  definition = function(.Object, value) {
    .Object@conditionScope <- value
    validObject(.Object)
    .Object
  }
)
