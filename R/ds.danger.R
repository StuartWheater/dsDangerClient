#' 
#' @title Computes the statistical mean of a given vector
#' @description This function is similar to the R function \code{mean}.
#' @details It is a wrapper for the server side function.
#' @param x a character, the name of a numerical vector
#' @param type a character which represents the type of analysis to carry out. 
#' If \code{type} is set to 'combine', a global mean is calculated 
#' if \code{type} is set to 'split', the mean is calculated separately for each study.
#' @param datasources a list of opal object(s) obtained after login in to opal servers;
#' these objects hold also the data assign to R, as \code{data frame}, from opal datasources.
#' @return a numeric
#' @author Gaye A., Isaeva I.
#' @seealso \code{ds.quantileMean} to compute quantiles.
#' @seealso \code{ds.summary} to generate the summary of a variable.
#' @export
#' 
ds.danger = function(x=NULL, type='combine', datasources=NULL){
  
  # if no opal login details are provided look for 'opal' objects in the environment
  if(is.null(datasources)){
    datasources <- findLoginObjects()
  }
  
  if(is.null(x)){
    stop("Please provide the name of the input vector!", call.=FALSE)
  }
  
  # the input variable might be given as column table (i.e. D$x)
  # or just as a vector not attached to a table (i.e. x)
  # we have to make sure the function deals with each case
  xnames <- extract(x)
  varname <- xnames$elements
  obj2lookfor <- xnames$holders
  
  # check if the input object(s) is(are) defined in all the studies
  if(is.na(obj2lookfor)){
    defined <- isDefined(datasources, varname)
  }else{
    defined <- isDefined(datasources, obj2lookfor)
  }
  
  # call the internal function that checks the input object is of the same class in all studies.
  typ <- checkClass(datasources, x)
  
  # the input object must be a numeric or an integer vector
  if(typ != 'integer' & typ != 'numeric'){
    stop("The input object must be an integer or a numeric vector.", call.=FALSE)
  }
  
  # number of studies
  num.sources <- length(datasources)
  
  cally <- paste0("meanDS(", x, ")")
  mean.local <- opal::datashield.aggregate(datasources, as.symbol(cally))
  
  cally <- paste0("NROW(", x, ")")
  length.local <- opal::datashield.aggregate(datasources, cally)
  
  # get the number of entries with missing values
  cally <- paste0("numNaDS(", x, ")")
  numNA.local <- opal::datashield.aggregate(datasources, cally)
  
  if (type=='split') {
    return(mean.local)
  } else if (type=='combine') {
    length.total = 0
    sum.weighted = 0
    mean.global  = NA
    
    for (i in 1:num.sources){
      if ((!is.null(length.local[[i]])) & (length.local[[i]]!=0)) {
        completeLength <- length.local[[i]]-numNA.local[[i]]
        length.total = length.total+completeLength
        sum.weighted = sum.weighted+completeLength*mean.local[[i]]
      }
    }
    
    mean.global = sum.weighted/length.total
    return(list("Global mean"=mean.global))
    
  } else{
    stop('Function argument "type" has to be either "combine" or "split"')
  }
  
}