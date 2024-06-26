#' @importFrom Matrix Matrix
#' @export scorpion
#' @title Constructs PANDA gene regulatory networks from single-cell gene expression data
#' @description  Constructs gene regulatory networks from single-cell gene expression data using the PANDA (Passing Attributes between Networks for Data Assimilation) algorithm.
#' @author Daniel Osorio <daniecos@uio.no>
#' @param tfMotifs A motif dataset, a data.frame or a matrix containing 3 columns. Each row describes an motif associated with a transcription factor (column 1) a gene (column 2) and a score (column 3) for the motif.
#' @param gexMatrix An expression dataset, with genes in the rows and barcodes (cells) in the columns.
#' @param ppiNet A Protein-Protein-Interaction dataset, a data.frame or matrix containing 3 columns. Each row describes a protein-protein interaction between transcription factor 1(column 1), transcription factor 2 (column 2) and a score (column 3) for the interaction.
#' @param nCores Number of processors to be used if BLAS or MPI is active.
#' @param gammaValue Graining level of data (proportion of number of single cells in the initial dataset to the number of super-cells in the final dataset)
#' @param nPC Number of principal components to use for construction of single-cell kNN network.
#' @param alphaValue Value to be used for update variable.
#' @param hammingValue Value at which to terminate the process based on Hamming distance.
#' @param assocMethod Association method. Must be one of 'pearson', 'spearman' or 'pcNet'.
#' @param nIter Sets the maximum number of iterations PANDA can run before exiting.
#' @param outNet A vector containing which networks to return. Options include "regulatory", "coregulatory", "cooperative".
#' @param zScaling Boolean to indicate use of Z-Scores in output. False will use [0,1] scale.
#' @param showProgress Boolean to indicate printing of output for algorithm progress.
#' @param randomizationMethod Method by which to randomize gene expression matrix. Default "None". Must be one of "None", "within.gene", "by.genes". "within.gene" randomization scrambles each row of the gene expression matrix, "by.gene" scrambles gene labels.
#' @param scaleByPresent Boolean to indicate scaling of correlations by percentage of positive samples.
#' @param filterExpr Boolean to indicate wheter or not to remove genes with 0 expression across all cells from the GEX input.
#' @return A list of matrices describing networks achieved by convergence with PANDA algorithm.
#' @examples
#' # Loading example data
#' data(scorpionTest)
#'
#' # The structure of the data
#' str(scorpionTest)
#'
#' # List of 3
#' # $ gex:Formal class 'dgCMatrix' [package "Matrix"] with 6 slots
#' # .. ..@ i       : int [1:4456] 1 5 8 11 22 30 33 34 36 38 ...
#' # .. ..@ p       : int [1:81] 0 47 99 149 205 258 306 342 387 423 ...
#' # .. ..@ Dim     : int [1:2] 230 80
#' # .. ..@ Dimnames:List of 2
#' # .. .. ..$ : chr [1:230] "MS4A1" "CD79B" "CD79A" "HLA-DRA" ...
#' # .. .. ..$ : chr [1:80] "ATGCCAGAACGACT" "CATGGCCTGTGCAT" "GAACCTGATGAACC" "TGACTGGATTCTCA" ...
#' # .. ..@ x       : num [1:4456] 1 1 3 1 1 4 1 5 1 1 ...
#' # .. ..@ factors : list()
#' # $ tf :'data.frame':	4485 obs. of  3 variables:
#' #   ..$ tf    : chr [1:4485] "ADNP" "ADNP" "ADNP" "AEBP2" ...
#' # ..$ target: chr [1:4485] "PRF1" "TMEM40" "TNFRSF1B" "CFP" ...
#' # ..$ mor   : num [1:4485] 1 1 1 1 1 1 1 1 1 1 ...
#' # $ ppi:'data.frame':	12754 obs. of  3 variables:
#' #   ..$ X.node1       : chr [1:12754] "ADNP" "ADNP" "ADNP" "AEBP2" ...
#' # ..$ node2         : chr [1:12754] "ZBTB14" "NFIA" "CDC5L" "YY1" ...
#' # ..$ combined_score: num [1:12754] 0.769 0.64 0.581 0.597 0.54 0.753 0.659 0.548 0.59 0.654 ...
#'
#' # Running SCORPION with large alphaValue for testing purposes.
#' scorpionOutput <- scorpion(tfMotifs = scorpionTest$tf,
#'                            gexMatrix = scorpionTest$gex,
#'                            ppiNet = scorpionTest$ppi,
#'                            alphaValue = 0.8)
#'
#' # -- SCORPION --------------------------------------------------------------------------------------
#' # + Initializing and validating
#' # + Verified sufficient samples
#' # i Normalizing networks
#' # i Learning Network
#' # i Using tanimoto similarity
#' # + Successfully ran SCORPION on 214 Genes and 783 TFs
#'
#' # Structure of the output.
#' str(scorpionOutput)
#'
#' # List of 6
#' # $ regNet  :Formal class 'dgeMatrix' [package "Matrix"] with 4 slots
#' # .. ..@ x       : num [1:167562] -0.413 1.517 -1.311 0.364 -1.041 ...
#' # .. ..@ Dim     : int [1:2] 783 214
#' # .. ..@ Dimnames:List of 2
#' # .. .. ..$ : chr [1:783] "ADNP" "AEBP2" "AIRE" "ALX1" ...
#' # .. .. ..$ : chr [1:214] "ACAP1" "ACRBP" "ACSM3" "ADAR" ...
#' # .. ..@ factors : list()
#' # $ coregNet:Formal class 'dgeMatrix' [package "Matrix"] with 4 slots
#' # .. ..@ x       : num [1:45796] 7.07e+06 -4.06 1.76e+01 -1.16e+01 -1.62e+01 ...
#' # .. ..@ Dim     : int [1:2] 214 214
#' # .. ..@ Dimnames:List of 2
#' # .. .. ..$ : chr [1:214] "ACAP1" "ACRBP" "ACSM3" "ADAR" ...
#' # .. .. ..$ : chr [1:214] "ACAP1" "ACRBP" "ACSM3" "ADAR" ...
#' # .. ..@ factors : list()
#' # $ coopNet :Formal class 'dgeMatrix' [package "Matrix"] with 4 slots
#' # .. ..@ x       : num [1:613089] 5.65e+06 -5.16 -3.79 -3.63 2.94 ...
#' # .. ..@ Dim     : int [1:2] 783 783
#' # .. ..@ Dimnames:List of 2
#' # .. .. ..$ : chr [1:783] "ADNP" "AEBP2" "AIRE" "ALX1" ...
#' # .. .. ..$ : chr [1:783] "ADNP" "AEBP2" "AIRE" "ALX1" ...
#' # .. ..@ factors : list()
#' # $ numGenes: int 214
#' # $ numTFs  : int 783
#' # $ numEdges: int 167562

scorpion <- function(tfMotifs = NULL,
                     gexMatrix,
                     ppiNet = NULL,
                     nCores = 1,
                     gammaValue = 10,
                     nPC = 25,
                     assocMethod = 'pearson',
                     alphaValue = 0.1,
                     hammingValue = 0.001,
                     nIter = Inf,
                     outNet = c('regulatory', 'coregulatory', 'cooperative'),
                     zScaling = TRUE,
                     showProgress = TRUE,
                     randomizationMethod = 'None',
                     scaleByPresent = FALSE,
                     filterExpr = FALSE) {

  cli::cli_h1('SCORPION')

  if(isTRUE(filterExpr)){
    gexMatrix <- gexMatrix[rowSums(gexMatrix) > 0,]
  }
  gexMatrix <- makeSuperCells(X = gexMatrix, gamma = gammaValue, n.pc = nPC, fast.pca = FALSE)

  if(is.null(ppiNet) & is.null(tfMotifs)){
    if(assocMethod == 'spearman'){
      gexMatrix <- Matrix(t(apply(gexMatrix, 1, rank)))
    }
    geneCoExpr <- gexMatrix - rowMeans(gexMatrix)
    geneCoExpr <- geneCoExpr/sqrt(rowSums(geneCoExpr^2))
    geneCoExpr <- tcrossprod(geneCoExpr)
    return(geneCoExpr)
  }
  outNetworks <- runPANDA(motif = tfMotifs,
                          ppi = ppiNet,
                          expr = gexMatrix,
                          n.cores = nCores,
                          alpha = alphaValue,
                          hamming = hammingValue,
                          iter = nIter,
                          output = outNet,
                          zScale = zScaling,
                          progress = showProgress ,
                          randomize = randomizationMethod ,
                          assoc.method = assocMethod,
                          scale.by.present = scaleByPresent)
  return(outNetworks)
}
