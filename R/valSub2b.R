require(RCurl)
require(RJSONIO)
require(synapseClient)
require(tools)

synapseLogin()

# the page size can be bigger, we do this just to demonstrate pagination
PAGE_SIZE <- 20
# the batch size can be bigger, we do this just to demonstrate batching
BATCH_SIZE <- 20

WAIT_FOR_QUERY_ANNOTATIONS_SEC <- 20L # must be under a minute
BATCH_UPLOAD_RETRY_COUNT<-3

updateSubmissionStatusBatch<-function(evaluation, statusesToUpdate){
  for(retry in 1:BATCH_UPLOAD_RETRY_COUNT){
    tryCatch({
      batchToken <- NULL
      offset <- 0
      while( offset < length(statusesToUpdate) ){
        batch <- statusesToUpdate[(offset+1):min(offset+BATCH_SIZE, length(statusesToUpdate))]
        updateBatch <- list(statuses=batch, 
                            isFirstBatch=(offset==0), 
                            isLastBatch=(offset+BATCH_SIZE>=length(statusesToUpdate)),
                            batchToken=batchToken)
        response <- synRestPUT(sprintf("/evaluation/%s/statusBatch",evaluation$id), updateBatch)
        batchToken <- response$nextUploadToken
        offset<-offset+BATCH_SIZE
      } # end while offset loop
      break
    }, 
    error=function(e){
      # on 412 ConflictingUpdateException we want to retry
      if(regexpr("412", e, fixed=TRUE)>0){
        # will retry
      } else{
        stop(e)
      }
    })
    if(retry < BATCH_UPLOAD_RETRY_COUNT){
      message("Encountered 412 error, will retry batch upload.")
    }
  }
}


validate <- function(evaluation){
  total <- 1e+10
  offset <- 0
  statusesToUpdate <- list()
  while( offset < total ){
    submissionBundles <- synRestGET(sprintf("/evaluation/%s/submission/bundle/all?limit=%s&offset=%s&status=%s",
                                            evaluation$id, PAGE_SIZE, offset, "RECEIVED"))
    total <- submissionBundles$totalNumberOfResults
    offset <- offset+PAGE_SIZE
    page <- submissionBundles$results
    if( length(page) > 0 ){
      for( i in 1:length(page) ){
        validInhib <- paste0("AB", 1:20)
        # need to download the file
        submission <- synGetSubmission(page[[i]]$submission$id)
        filePath <- getFileLocation(submission)
        # challenge-specific validation of the downloaded file goes here
        newPlace <- unzip(filePath, exdir = tempdir())
        theseExts <- file_ext(newPlace)
        if( sum(theseExts=="csv")==20 ){
          aaa <- strsplit(basename(newPlace[theseExts=="csv"]), "-", fixed=T)
          inhib <- sapply(aaa, function(x){
            x[length(x)-2]
          })
          if( all(validInhib %in% inhib) ){
            isValid <- TRUE
          } else{
            isValid <- FALSE
          }
        } else{
          isValid <- FALSE
        }
        
        if(isValid){
          newStatus <- "VALIDATED"
          sendMessage(list(submission@submissionContent@userId), "Submission Acknowledgment", "Your submission has the right structure - you'll get another email once your submission is scored.")
        } else{
          newStatus<-"INVALID"
          sendMessage(list(submission@submissionContent@userId), "Submission Acknowledgment", "Your submission is invalid. Please try again.")
        }
        subStatus <- page[[i]]$submissionStatus
        subStatus$status <- newStatus
        statusesToUpdate[[length(statusesToUpdate)+1]] <- subStatus
      }
    }
  }
  updateSubmissionStatusBatch(evaluation, statusesToUpdate)
}

ev <- synGetEvaluation("4013814")
validate(ev)
