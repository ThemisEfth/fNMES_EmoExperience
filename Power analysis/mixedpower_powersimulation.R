#' Function trunning the actual power simulation
#'
#' \code{power_simulation()} runs the actual simulation process for either the
#' databased, SESOI, R2, safeguard or rnorm power option. Returns a data frame with results
#' for all fixed effects and all tested sample sizes.
#'
#' @param model lme4 model: mixed model of interest
#' @param data data frame: pilot data that fits the mixed model of interest
#' @param simvar charackter element: name of the variable that contains the
#' subject??s number
#' in data
#' @param fixed_effects vector of character elements: names of variables that
#'  are used as fixed effects in
#' model emp
#' @param critical_value integer: z/t value to test if a given fixed effect
#' is significant
#' @param sampe_sizes vector of integers: sample sizes you want to test power
#'of
#' @param n_sim integer: number of simulations to run
#' @param safeguard logical value: indicates whether safeguard power simulation
#' shoul be run
#' @param rnorm logical value: indicates whether rnorm power simulation
#' shoul be run
#' @param R2 logical value: indicating if a R2 simulation should be run
#' @param R2var character: name of second random effect we want to vary
#' @param R2level integer: number of levels for R2var. Right now, the second
#' random effect can only be changed to a fixed value and not be varied like
#' simvar
#' @return A modified mixed model
#'
#' @export
power_simulation <- function(model, data, simvar, fixed_effects,
                             critical_value, steps, n_sim, confidence_level,
                             safeguard = F, rnorm = F,
                             R2 = F, R2var, R2level){
  
  
  
  # PREPARE:
  # get depvar from model to hand it siimulateSamplesize() later
  depvar <- get_depvar(model)
  
  
  # PREPARE TO RUN IN PARALLEL
  cores= parallel::detectCores()
  cl <- parallel::makeCluster(cores[1]-1) #not to overload your computer
  doParallel::registerDoParallel(cl)
  
  #------------------------------------#
  #------------------------------------#
  # IF SAFEGUARD POWER: (only active if used in mixedpower1)
  if (safeguard == T){
    model_for_simulation <- prepare_safeguard_model(model,
                                                    confidence_level,
                                                    critical_value)
  } else {
    model_for_simulation <- model
  }
  
  #------------------------------------#
  #------------------------------------#
  
  #------------------------------------#
  # ENTER 2 STEP SIMULATION
  #------------------------------------#
  
  
  #------------------------------------#
  # prepare storing power values
  
  ## 1. create an empty data frame witg the right dimensions and names
  # dimension = ncol, nrow
  # [-1] removes the Intercept
  n_row <- length(lme4::fixef(model)[-1])
  # n col
  n_col <- length(steps)
  
  # row_names = names of effects (again remove intercept)
  row_names <- row.names(summary(model)$coefficients)[-1]
  
  # empty data frame
  power_values_all <- data.frame(matrix(ncol = n_col, nrow = n_row),
                                 row.names = row_names)
  # name stuff (header)
  names(power_values_all) <- steps
  
  index_n <- 0 # index to store power value in Power_value later
  
  # loop through different sample sizes
  for (n in steps){
    
    # inform which sample sizes we are computing power right now
    print("Estimating power for step:")
    print(n)
    
    index_n <- index_n + 1
    
    # prepare simulation for current n
    ## 1. create object that can store simulations
    #--> data frame with effects as collumns and nsim rows
    #store_simulations <- data.frame(matrix(ncol = n_row, nrow = n_sim))
    #names(store_simulations) <- names(fixef(model)[-1])
    
    # repeat simulation n_sim times
    # store outcome in store_simulations
    # --> this is a list of vectors!!
    
    # magic cheating
    `%dopar%` <- foreach::`%dopar%`
    #okay now continue
    store_simulations <- suppressWarnings(foreach::foreach(iterators::icount(n_sim),
                                                           .combine = "cbind",
                                                           .export=ls(envir=globalenv()),
                                                           .packages = c("lme4"),
                                                           .errorhandling = "remove") %dopar% {
                                                             
                                                             
                                                             #------------------------------------#
                                                             #------------------------------------#
                                                             # IF RNORM MODEL: (only active if used in mixedpower1)
                                                             if (rnorm == T){
                                                               model_for_simulation <- prepare_rnorm_model(model,
                                                                                                           data,
                                                                                                           simvar,
                                                                                                           critical_value)
                                                             }
                                                             
                                                             
                                                             #------------------------------------#
                                                             #------------------------------------#
                                                             
                                                             #-------------------------------------#
                                                             
                                                             # 1. simulate data set with n subjects
                                                             simulated_data <- simulateDataset(n_want = n,
                                                                                               data = data,
                                                                                               model = model_for_simulation,
                                                                                               simvar = simvar,
                                                                                               fixed_effects= fixed_effects)
                                                             
                                                             #------------------------------------#
                                                             #2. code contrasts for simulated data set
                                                             final_dataset <- reset_contrasts(simulated_data,
                                                                                              data,
                                                                                              model,
                                                                                              fixed_effects)
                                                             
                                                             
                                                             #-------------------------------------#
                                                             # 3. refit model to current data set (final_dataset)
                                                             # --> update model emp with new data set
                                                             model_final <- update(model,
                                                                                   data = final_dataset)
                                                             
                                                             if (R2 == T){
                                                               
                                                               # ----- simulate and update model to R2 level ---- #
                                                               # simulate dataset:
                                                               
                                                               model_final@beta <- model_for_simulation@beta
                                                               
                                                               
                                                               sim_data2 <- simulateDataset(n_want = R2level,
                                                                                            final_dataset, model_final,
                                                                                            simvar = R2var,
                                                                                            fixed_effects= fixed_effects,
                                                                                            use_u = T)
                                                               
                                                               
                                                               # reset contrasts
                                                               sim_data2 <- reset_contrasts(sim_data2,
                                                                                            data,
                                                                                            model,
                                                                                            fixed_effects)
                                                               
                                                               # reassign sim_data as data
                                                               
                                                               
                                                               # update model
                                                               model_R2_final <- update(model, data = sim_data2)
                                                               
                                                               # keep beta coeficcients from first simulation
                                                               #model_R2_final@beta <- model_final@beta
                                                               
                                                             }
                                                             
                                                             
                                                             #-------------------------------------#
                                                             # 4. analyze final_data set and store result
                                                             
                                                             
                                                             
                                                             # check significance
                                                             # --> check_significance() returns 1 if effect is significant, 0 if not
                                                             # --> store significance in specified vector
                                                             if (R2 == F){
                                                               to.store_simulations <- check_significance(model_final,
                                                                                                          critical_value)
                                                             } else {
                                                               to.store_simulations <- check_significance(model_R2_final,
                                                                                                          critical_value)
                                                             }
                                                             
                                                             
                                                           })# end for loop (n_sim))
    
    # -------------------------------------#
    # 5. compute power
    ## compute power!
    # margin = 2 --> apply FUN on columns
    # --> vector withs names
    print(paste("Simulations for step ", n, " are based on ", length(store_simulations)/n_row, " successful single runs"))
    power_values_n <- apply(store_simulations, MARGIN = 1,
                            FUN = mean, na.rm = T)
    
    # -------------------------------------#
    # 6. store power value
    ## store it!
    column_name <- as.character(n)
    power_values_all[column_name] <- power_values_n
    
  } # end for loop (samplesizes)
  
  ## END PARALLEL PROCESSING
  parallel::stopCluster(cl)
  
  # return data based power values
  power_values_all
  
  
} # end power simulation function



#-----------------------------------------------------------------------------#


#' Simulate a new data set
#'
#' \code{simulateDataset()} builds a new data set with a specified number of
#' subjects. It uses the \code{lme4::simulate()} function to create new response
#' values based on the mixed model fittet to the pilot data.
#'
#' @param n_want integer: how many subjects should the new data set include?
#' @param data data frame: pilot data that fits the mixed model of interest
#' @param model lme4 model: mixed model of interest
#' @param simvar character element: name of the varaible containing the subject
#' @param fixed_effects fixed effects specified in model
#' number in data
#'
#' @return A modified mixed model
#'
#' @export

simulateDataset <- function(n_want, data, model, simvar, fixed_effects, use_u = F){
  # ---------------------------------------------------------------------------- #
  # STEP 1: set relevant paramaters
  
  # whats the dependent variable?
  depvar <- get_depvar(model)
  
  # how many subjects are in the pilot data? --> n_now
  n_now <- get_n(data, simvar)
  
  # number of dublicates we need from the original dataset # --> ceiling()
  # --> floor gets next lower integer (we already have one multiplication with exp4)
  mult_factor <- ceiling(n_want/n_now)
  
  # --> how many subjects do we need to remove if we use this multiplication factor?
  too_much <- (n_now*mult_factor) - n_want
  
  # --------------------------------------------------------------------------- #
  # STEP 2: sumulate data set
  
  sim_data <- lme4:::simulate.merMod(model, nsim = mult_factor, use.u = use_u, na.action = na.exclude)
  
  
  # simulate (mult_factor) data sets
  for (i in 1:mult_factor){
    
    
    
    ###--- create new data set: rename vp variable and replace variable of interest with simulated data--- ##
    # copy old data set
    new_part <- data
    
    
    
    # first iteration: only change variable of interest
    if (i==1){
      new_part[[depvar]] <- sim_data[[i]]
      final_data <- new_part
      # from second iteration on: change subject names and rbind new data to existing data
    } else {
      
      
      
      # 1. increment vp variable wih current n and replce the old names
      # --> change subjects names only from second iteration on
      
      # check if it is a factor
      if( is.numeric(final_data[[simvar]]) == F) {
        # do step 1.
        
        new_names <- as.numeric(as.character(new_part[[simvar]])) + (i-1)*n_now
        new_part[[simvar]] <- new_names
        
        # re-convert simvar to a factor
        new_part[[simvar]] <- as.factor(new_part[[simvar]])
      } else {
        
        # do step 1.
        new_names <- new_part[[simvar]] + (i-1)*n_now
        new_part[[simvar]] <- new_names
        
      } # end inner if else
      
      
      # 2. replace variable of interest
      new_part[[depvar]] <- sim_data[[i]]
      
      # 3. combine new and old data set
      # --> if first iteration: nothing to rbind, so just new_part it is
      # --> second and more iteration: rbind new simulated subjects to already simulated ones
      final_data <- rbind(final_data, new_part)
    } # end outer if else
  } # end for-loop
  
  # --------------------------------------------------------------------------- #
  # STEP 3: delete participants to get the exact n  and return it
  
  #--> simvar needs to be numeric for that, so it needs to be converted temporarly
  
  # select which subjects to keep
  simvar_keep <- keep_balance(final_data, simvar, fixed_effects, n_want)
  
  # check if it is a factor
  if( is.numeric(final_data[[simvar]]) == F) {
    # 2. convert  to numeric
    final_data[[simvar]] <- as.numeric(as.character(final_data[[simvar]]))
    
    
    # now do STEP 3:
    final_data <- final_data[is.element(final_data[[simvar]], simvar_keep),]
    #final_data <- final_data[final_data[[simvar]] <= n_want,] # old solution
    
    # re-convert to factor
    final_data[[simvar]] <- as.factor(final_data[[simvar]])
    
    # if not: just subset final data to correct n
  } else {
    final_data <- final_data[is.element(final_data[[simvar]], simvar_keep),]
    #final_data <- final_data[final_data[[simvar]] <= n_want,] # old solution
  }# end if
  
  
  # return final_data
  final_data
}


#-----------------------------------------------------------------------------#

#' Simulate a new data set
#'
#' \code{simulateModel()} builds a new model set with a specified number of
#' levels of a specified random effect.
#'
#' @param model lme4 model: starting mixed model used for simulation
#' @param data data frame: data used to inform the simulation
#' @param n_want integer: how many levels should the new model be based on?
#' @param simvar character element: name of the varaible containing
#' the random effect levels
#' @param fixed_effects vector containing variable names used as fixed effects

#' @return A modified mixed model
#'
#' @export


simulateModel <- function(model, data, n_want, simvar, fixed_effects){
  
  
  # ----- simulate and update model ---- #
  # simulate dataset:
  sim_data <- simulateDataset(n_want, data, model, simvar, fixed_effects)
  
  
  # reset contrasts
  sim_data <- reset_contrasts(sim_data,
                              data,
                              model,
                              fixed_effects)
  
  # update model
  sim_model <- update(model, data = sim_data)
  
  # WHY TF AM I DOING THIS?!
  # ----- store and average ----- #
  # extract variances and coefficients and std and t values!
  #coefs <- sim_model@beta
  #theta <- sim_model@theta
  
  
  # -------- prepare simulated model ----- #
  #model_return <- model
  #model_return@beta <- coefs # assign new coeffs
  #model_return@theta <- theta # assign new random variances
  
  # return
  #model_return
  sim_model
  
} # end function