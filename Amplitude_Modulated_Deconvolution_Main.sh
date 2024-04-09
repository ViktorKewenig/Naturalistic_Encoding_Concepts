#!/bin/bash

################################################################################
# Do LSS
################################################################################

# NOTES
# https://www.sciencedirect.com/science/article/pii/S1053811911010081
# https://afni.nimh.nih.gov/pub/dist/doc/program_help/3dLSS.html
# https://openwetware.org/wiki/Beauchamp:ROIanalysis

################################################################################
# Set some variables
################################################################################

# Steps to run
#   make_regressors = makes annotation files and associated convovled regressors,.mat, and .con files for the FSL GLMs
#   do_regressions = run FSL GLMs using convovled regressorson ICA components, find significant ICs, and combines them
#   do_ttests = runs group level 3dttest++ on the combined IC files
# steps_order="make_regressors do_regressions do_ttests"
# steps_order="make_regressors"
steps_order="do_regressions"
# steps_order="do_ttests"

# Redo glms?
# Do not need to if just redoing thresh
# redo_glm="yes"
# redo_glm="no"

# Directories
# Base
base_data_dir="/data/movie/fmri/participants/adults"

# Functional data
ica_file="errts.ap.fanaticor.blur.no.censor.run.all.timing.ica.nii.gz"
mask_file="mask_epi_anat.ap.nii.gz"
# Annotations to use
sarah_dir="$base_data_dir"/sarah_word_averaging
annotation_dir="$base_data_dir"/RSA_project/V_regression_np
regressor_dir="/data/movie/fmri/stimuli"
#annotation_1="start_duration"
# Filtered regressors for IM
annotation_2="ndp_brysbaert_cat"
annotation_1="ndp_others1"
annotation_3="no_words"
annotation_2_suffix_1="brysbaert_luminance_soundpower_wordfrequency"
annotation_1_suffix_1="others_luminance_soundpower_wordfrequency"

orig_files=(`ls "$base_data_dir"/*/*/*/"$ica_file"`)
#mask_files=(`ls "$base_data_dir"/500_days/*/ap.results/"$mask_file".nii.gz`)

################################################################################
# Begin
################################################################################

for step in $steps_order
do

################################################################################
# Make convolved regressors
################################################################################

# NOTES
  if [[ $step = do_regressions ]]
  then
    for i in ${!orig_files[@]}
    do
      mov=`echo ${orig_files[i]} | awk -F / '{print $7}'`
      perp=`echo ${orig_files[i]} | awk -F / '{print $8}'`
      mask_file="$base_data_dir"/"$mov"/"$perp$_afni_proc"/ap.results/mask_epi_anat.ap.nii.gz
      # 12 years a slave
      if [[ $mov == "12_years_a_slave" ]]
      then
        export movie_length="7715"
      # 500 Days of Summer
      elif [[ $mov == "500_days" ]]
      then
        export movie_length="5470"
        export mov="500_days_of_summer"
      # Back to the Future
      elif [[ $mov == "back_to_the_future" ]]
      then
        export movie_length="6674"
      # CitizenFour
      elif [[ $mov == "citizenfour" ]]
      then
        export movie_length="6804"
      # Little Miss Sunshine
      elif [[ $mov == "little_miss_sunshine" ]]
      then
        export movie_length="5900"
      # Pulp Fiction
      elif [[ $mov == "pulp_fiction" ]]
      then
        export movie_length="8882"
      # Split
      elif [[ $mov == "split" ]]
      then
        export movie_length="6739"
      # The Prestige
      elif [[ $mov == "the_prestige" ]]
      then
        export movie_length="7515"
      # The Shawshank Redemption
      elif [[ $mov == "the_shawshank_redemption" ]]
      then
        export movie_length="8181"
      # The Usual Suspects
      elif [[ $mov == "the_usual_suspects" ]]
      then
        export movie_length="6102"
      fi
      # Change directory
      data_dir="$base_data_dir"/"$mov"
      cd "$annotation_dir"
#      rm "$perp"_"$annotation_1"_"$annotation_2_suffix_1"_convolved_coef.nii.gz
      echo "################################################################################"
      echo "# "$perp": Doing 3dDeconvolve for "$mov""
      echo "################################################################################"
#      if [[ ! -f "$perp"_"$annotation_1"_"$annotation_2_suffix_1"_convolved_coef.nii.gz ]]
      3dDeconvolve \
           -polort -1 \
           -global_times \
           -input "${orig_files[$i]}" \
           -mask "$mask_file" \
           -num_stimts 4 \
	   -GOFORIT 1 \
           -stim_times_AM2 1 "$annotation_dir"/"$mov"_"$annotation_1"_regressors.1D 'CSPLIN(0,20,20)' -stim_label 1 "others" \
           -stim_times_AM2 2 "$annotation_dir"/"$mov"_"$annotation_2"_regressors_abstr.1D 'CSPLIN(0,20,20)' -stim_label 2 "abstract" \
           -stim_times_AM2 3 "$annotation_dir"/"$mov"_"$annotation_2"_regressors_concr.1D 'CSPLIN(0,20,20)' -stim_label 3 "concrete" \
	   -stim_times_AM2 4 "$annotation_dir"/"$mov"_"no_words"_regressor.1D 'CSPLIN(0,20,20)' -stim_label 4 "no_words" \
	   -gltsym "SYM: +abstract" -glt_label 1 "abstract_auc" \
	   -gltsym "SYM: +concrete" -glt_label 2 "concrete_auc" \
	   -gltsym "SYM: +no_words" -glt_label 3 "no_words_auc" \
	   -gltsym "SYM: +others" -glt_label 4 "others_auc" \
	   -gltsym "SYM: +abstract -concrete" -glt_label 5 "concrete-abstract_auc" \
	   -gltsym "SYM: +abstract +concrete" -glt_label 6 "concrete+abstract_auc" \
	   -gltsym "SYM: +abstract[[0..19]] +concrete[[0..19]]" -glt_label 7 "concrete+abstract_tps" \
	   -gltsym "SYM: +concrete[[0..19]] -abstract[[0..19]]" -glt_label 8 "concrete-abstract_tps" \
	   -jobs 20 \
           -errts "$perp"_errts.nii.gz \
           -fout -tout -full_first \
           -xsave \
           -x1D     "$perp"_"$annotation_1"_"$annotation_2_suffix_1"_convolved_cat \
           -fitts   "$perp"_"$annotation_1"_"$annotation_2_suffix_1"_convolved_cat.nii.gz \
           -cbucket "$perp"_"$annotation_1"_"$annotation_2_suffix_1"_convolved_coef_cat.nii.gz \
           -bucket  "$perp"_"$annotation_1"_"$annotation_2_suffix_1"_convolved_stats_cat.nii.gz 
    done
  elif [[ $step == do_testing ]]
  then
    for i in ${!orig_files[@]}
    do
      mov=`echo ${orig_files[i]} | awk -F / '{print $7}'`
       # 12 years a slave
      if [[ $mov == "12_years_a_slave" ]]
      then
        export movie_length="7715"
      # 500 Days of Summer
      elif [[ $mov == "500_days" ]]
      then
        export movie_length="5470"
        export mov="500_days_of_summer"
      # Back to the Future
      elif [[ $mov == "back_to_the_future" ]]
      then
        export movie_length="6674"
      # CitizenFour
      elif [[ $mov == "citizenfour" ]]
      then
        export movie_length="6804"
      # Little Miss Sunshine
      elif [[ $mov == "little_miss_sunshine" ]]
      then
        export movie_length="5900"
      # Pulp Fiction
      elif [[ $mov == "pulp_fiction" ]]
      then
        export movie_length="8882"
      # Split
      elif [[ $mov == "split" ]]
      then
        export movie_length="6739"
      # The Prestige
      elif [[ $mov == "the_prestige" ]]
      then
        export movie_length="7515"
      # The Shawshank Redemption
      elif [[ $mov == "the_shawshank_redemption" ]]
      then
        export movie_length="8181"
      # The Usual Suspects
      elif [[ $mov == "the_usual_suspects" ]]
      then
        export movie_length="6102"
      fi
      cd $regressor_dir
       3dDeconvolve \
         -polort -1 \
         -nodata "$movie_length" 1 \
         -num_stimts 4 \
         -global_times \
         -stim_times_AM1 1 "$regressor_dir"/$mov/"$mov"_visual_regressors.1D 'dmUBLOCK' -stim_label 1 visual \
         -stim_times_AM1 2 "$regressor_dir"/$mov/"$mov"_soundpower_afni.1D 'dmUBLOCK' -stim_label 2 soundpower \
         -stim_times_AM1 3 "$annotation_dir"/"$mov"_"$annotation_1"_"$annotation_2_suffix_1".1D 'dmUBLOCK' -stim_label 3 "$annotation_2_suffix_1"_"$annotation_1" \
         -stim_times_AM2 4 "$annotation_dir"/"$mov"_"$annotation_1"_"$annotation_1_suffix_1".1D 'dmUBLOCK' -stim_label 4 "$annotation_1_suffix_1"_"$annotation_1" \
         -x1D "$mov"_visual_soundpower_words_convolved -x1D_stop
         # Make mat file needed by fsl
    done


  fi

################################################################################
# END
################################################################################

done

