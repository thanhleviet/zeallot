#' Unpacking Operator
#'
#' Assign values to name(s).
#'
#' @usage x \%<-\% value
#'
#' @param x A bare name or name structure, see details.
#' @param value A list of values, vector of values, or \R object to assign.
#'
#' @details
#'
#' \bold{variable names}
#'
#' To separate variable names use colons, \code{a: b: c}.
#'
#' To nest variable names use braces, \code{\{a: \{b: c\}\}}.
#'
#' \bold{values}
#'
#' To unpack a vector of variables do not include braces, \code{a: b \%<-\% c(1,
#' 2)}.
#'
#' Include braces to unpack a list of values, \code{\{a: b\} \%<-\% list(1,
#' 2)}.
#'
#' When \code{value} is neither a vector nor a list, the zeallot operator will
#' try to de-structure \code{value} into a list, see \code{\link{destructure}}.
#'
#' Nesting names will unpack nested values, \code{\{a: \{b: c\}\} \%<-\% list(1,
#' list(2, 3))}.
#'
#' \bold{collector variables}
#'
#' To gather extra values from the beginning, middle, or end of \code{value}
#' use a collector variable. Collector variables are indicated with a \code{...}
#' prefix.
#'
#' Collect starting values, \code{\{...a: b: c\} \%<-\% list(1, 2, 3, 4)}
#'
#' Collect middle values, \code{\{a: ...b: c\} \%<-\% list(1, 2, 3, 4)}
#'
#' Collect ending values, \code{\{a: b: ...c\} \%<-\% list(1, 2, 3, 4)}
#'
#' \bold{skipping values}
#'
#' Use a period \code{.} in place of a variable name to skip a value without
#' raising an error, \code{\{a: .: c\} \%<-\% list(1, 2, 3)}. Values will not be
#' assigned to \code{.}.
#'
#' Skip multiple values by combining the collector prefix and a period,
#' \code{\{a: ....: e\} \%<-\% list(1, NA, NA, NA, 5)}.
#'
#' @return
#'
#' \code{\%<-\%} invisibly returns \code{value}.
#'
#' \code{\%<-\%} is used primarily for its assignment side-effect. \code{\%<-\%}
#' assigns into the environment in which it is evaluated.
#'
#' @seealso \code{\link{destructure}}
#'
#' @rdname unpacking-op
#' @export
#' @examples
#' # basic usage
#' {a: b} %<-% list(0, 1)
#'
#' a  # 0
#' b  # 1
#'
#' # no braces when unpacking vectors
#' c: d  %<-% c(0, 1)
#'
#' c  # 0
#' d  # 1
#'
#' # unpack and assign nested values
#' {{e: f}: {g: h}} %<-% list(list(2, 3), list(3, 4))
#'
#' e  # 2
#' f  # 3
#' g  # 4
#' h  # 5
#'
#' # can assign more than 2 values
#' {j: k: l} %<-% list(6, 7, 8)
#'
#' # assign columns of data frame
#' {num_erupts: till_next} %<-% faithful
#'
#' num_erupts  # 3.600 1.800 3.333 ..
#' till_next   # 79 54 74 ..
#'
#' # assign only specific columns, skip
#' # other columns
#' {mpg: cyl: disp: ....} %<-% mtcars
#'
#' mpg   # 21.0 21.0 22.8 ..
#' cyl   # 6 6 4 ..
#' disp  # 160.0 160.0 108.0 ..
#'
#' # skip initial values, assign final value
#' TODOs <- list('make food', 'pack lunch', 'save world')
#'
#' {....: task} %<-% TODOs
#'
#' task  # 'save world'
#'
#' # assign first name, skip middle initial,
#' # assign last name
#' first: .: last %<-% c('Ursula', 'K', 'Le Guin')
#'
#' first  # 'Ursula'
#' last   # 'Le Guin'
#'
#' # simple model and summary
#' f <- lm(hp ~ gear, data = mtcars)
#' fsum <- summary(f)
#'
#' # extract call and fstatistic from
#' # the summary
#' {fcall: ....: ffstat: .} %<-% fsum
#'
#' fcall
#' ffstat
#'
#' # unpack nested values with
#' # nested names
#' fibs <- list(1, list(2, list(3, list(5))))
#'
#' {f2: {f3: {f4: {f5}}}} %<-% fibs
#'
#' f2  # 1
#' f3  # 2
#' f4  # 3
#' f5  # list(5) *!!*
#'
#' # unpack first value (a numeric) and
#' # second value (a list)
#' {f2: fcdr} %<-% fibs
#'
#' f2    # 1
#' fcdr  # list(2, list(3, list(5)))
#'
#' # swap values without using a
#' # temporary variable
#' a: b %<-% c('eh', 'bee')
#' a  # 'eh'
#' b  # 'bee'
#'
#' a: b %<-% c(b, a)
#' a  # 'bee'
#' b  # 'eh'
#'
#' # unpack strsplit return value
#' names <- c('Nathan,Maria,Matt,Polly', 'Smith,Peterson,Williams,Jones')
#'
#' {firsts: lasts} %<-% strsplit(names, ',')
#'
#' firsts  # c('Nathan', 'Maria', ..
#' lasts   # c('Smith', 'Peterson', ..
#'
`%<-%` <- function(x, value) {
  ast <- tree(substitute(x))
  internals <- unlist(calls(ast))
  cenv <- parent.frame()

  if (!is.null(internals)) {

    if (any(!(internals %in% c(':', '{')))) {
      name <- internals[which(!(internals %in% c(':', '{')))][1]
      stop('unexpected call `', name, '`', call. = FALSE)
    }

    if (internals[1] == ':' && !(is.atomic(value) || is_Date(value))) {
      stop('expecting vector of values, but found ', class(value),
           call. = FALSE)
    }

    # NULL as a value slips through here, bug or feature?
    if (internals[1] == '{' && is.vector(value) && !is_list(value)) {
      stop('expecting list of values, but found vector', call. = FALSE)
    }

  } else {
    stop('use `<-` for standard assignment', call. = FALSE)
  }

  lhs <- variables(ast)
  if (is_list(lhs) && is_list(car(lhs))) {
    lhs <- car(lhs)
  }

  rhs <- value
  if (length(value) == 0) {
    rhs <- list(value)
  } else if (is.atomic(value)) {
    rhs <- as.list(value)
  } else if (!is_list(value)) {
    rhs <- list(value)
  }

  massign(lhs, rhs, envir = cenv)

  invisible(value)
}
