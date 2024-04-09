#!/bin/bash

################################################################################
# PPI_Thr script
################################################################################   

#step=ppi_thr01 
step=ppi_thr02
#time_line="8 10 12 14 16 18 20 22 24 26 28 30 32 34 36 38 40 42 44 46"
time_line="1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20"

if [[ $step = ppi_thr01 ]]; then
  ################################################################################
  echo ""
  echo "********************************************** Cluster Simulation for lme"
  echo ""
  ################################################################################

  # NOTES
  # Gleaned how to do clustersize from these
  # https://afni.nimh.nih.gov/afni/community/board/read.php?1,156149,156170
  #   - 'Theoretically speaking the ACF estimates from the 3dLME residuals should be fine for 3dClustSim.'.
  # https://afni.nimh.nih.gov/afni/community/board/read.php?1,158417,158449#msg-158449
  # Set file name
  for time in $time_line
  do
    acf=`3dFWHMx \
      -ACF NULL -automask \
      -input residuals_high_low.nii.gz["$time"]`
      # Put acf in variables
      acf1=`echo $acf | awk '{print $18}'`
      acf2=`echo $acf | awk '{print $19}'`
      acf3=`echo $acf | awk '{print $20}'`
      echo $acf1 $acf2 $acf3
    # Cluster
    # Increase iterations as we are going out to .0001
    # I think 10,000 is fine up to .001
    # -pthr 0.05 0.02 0.01 0.005 0.002 0.001 0.0005 0.0002 0.0001 \
    # -athr 0.05 0.02 0.01 0.005 0.002 0.001 0.0005 0.0002 0.0001 \
    # > .001 = 100001
    3dClustSim \
      -acf $acf1 $acf2 $acf3 \
      -nodec -both -iter 10001 \
      -pthr 0.05 0.02 0.01 0.005 0.002 0.001 \
      -athr 0.05 0.02 0.01 0.005 0.002 0.001 \
      -mask anatomical_mask_avg_automask.nii.gz \
      -prefix lme_resid_clustsim_abstract_low_"$time"_
    # Apply to results
    3drefit \
      -atrstring AFNI_CLUSTSIM_NN1_1sided lme_resid_clustsim_abstract_low.NN1_1sided_"$time".niml \
      -atrstring AFNI_CLUSTSIM_MASK lme_resid_clustsim_abstract_low_"$time".mask \
      -atrstring AFNI_CLUSTSIM_NN2_1sided lme_resid_clustsim_abstract_low.NN2_1sided_"$time".niml \
      -atrstring AFNI_CLUSTSIM_NN3_1sided lme_resid_clustsim_abstract_low.NN3_1sided_"$time".niml \
      -atrstring AFNI_CLUSTSIM_NN1_2sided lme_resid_clustsim_abstract_low.NN1_2sided_"$time".niml \
      -atrstring AFNI_CLUSTSIM_NN2_2sided lme_resid_clustsim_abstract_low.NN2_2sided_"$time".niml \
      -atrstring AFNI_CLUSTSIM_NN3_2sided lme_resid_clustsim_abstract_low.NN3_2sided_"$time".niml \
      -atrstring AFNI_CLUSTSIM_NN1_bisided lme_resid_clustsim_abstract_low.NN1_bisided_"$time".niml \
      -atrstring AFNI_CLUSTSIM_NN2_bisided lme_resid_clustsim_abstract_low.NN2_bisided_"$time".niml \
      -atrstring AFNI_CLUSTSIM_NN3_bisided lme_resid_clustsim_abstract_low.NN3_bisided._"$time"niml \
      lme_abstract_low_"$time".nii.gz
  done
fi

if [[ $step = ppi_thr02 ]]; then
#  time_line="8 10 12 14 16 18 20 22 24 26 28 30 32 34 36 38 40 42 44 46"
  ################################################################################
  echo ""
  echo "************************************************* Threshold Group Results"
  echo ""
  ################################################################################

  # NOTES
  # This does multi-thresholding over 9 individual voxel p-values and the corresponding cluster-size to reach a corrected threshold of alpha = .01  # Run 3dmerge
  pthresholds="05 02 01 005 002 001"
  # alpha = 001 = column 6
  # alpha = 01  = column 3
  athreshold_col="6"
  # directory
  for time in $time_line
  do
    cluster_table=lme_resid_clustsim_abstract_low_"$time"_.NN1_bisided.1D
    # Get all time based glts to make composite images from
 #   out_names=`3dinfo -verb lme__seeds_"$time".nii.gz 2>/dev/null | grep Z | grep -v _t | sed s/\'//g | sed s/_t0//g | awk '{print $5}'`
    for pthreshold in $pthresholds
    do
      if [ "$pthreshold" = "05" ]
      then
        cs=`cat $cluster_table | awk -v var="$athreshold_col" 'NR == 9 {print $var}'`
        echo cs
        thresh=1.96
      fi
      if [ "$pthreshold" = "02" ]
      then
        echo cs 
        cs=`cat $cluster_table | awk -v var="$athreshold_col" 'NR == 10 {print $var}'`
        thresh=2.33
      fi
      if [ "$pthreshold" = "01" ]
      then
        echo cs
        cs=`cat $cluster_table | awk -v var="$athreshold_col" 'NR == 11 {print $var}'`
        thresh=2.58
      fi
      if [ "$pthreshold" = "005" ]
      then
        echo cs
        cs=`cat $cluster_table | awk -v var="$athreshold_col" 'NR == 12 {print $var}'`
        thresh=2.81
      fi
      if [ "$pthreshold" = "002" ]
      then
        echo cs
        cs=`cat $cluster_table | awk -v var="$athreshold_col" 'NR == 13 {print $var}'`
        thresh=3.09
      fi
      if [ "$pthreshold" = "001" ]
      then
        echo cs
        cs=`cat $cluster_table | awk -v var="$athreshold_col" 'NR == 14 {print $var}'`
        thresh=3.29
      fi
      if [ "$pthreshold" = "0005" ]
      then
        echo cs
        cs=`cat $cluster_table | awk -v var="$athreshold_col" 'NR == 15 {print $var}'`
        thresh=3.48
      fi
      if [ "$pthreshold" = "0002" ]
      then
        echo cs
        cs=`cat $cluster_table | awk -v var="$athreshold_col" 'NR == 16 {print $var}'`
        thresh=3.72
      fi
      if [ "$pthreshold" = "0001" ]
      then
        echo cs
        cs=`cat $cluster_table | awk -v var="$athreshold_col" 'NR == 17 {print $var}'`
        thresh=3.89
      fi
#      for out_name in $out_names
#      do
        # This gets rid of dashed to make searching easier with grep to find the brik
        # B/c grep treats '-' like a space
#        out_name_dashless=`echo $out_name | sed 's/-//g'`
        # Get the start brik
#        brik=`3dinfo -verb LME_Glts_no_baseline.nii.gz 2>/dev/null | grep Z | grep -v _t | sed s/\'//g | sed 's/-//g' | grep -w $out_name_dashless | sed s/#//g | awk '{print $3}'`
        # Positive activity
#        rm lme__seeds_"$time"_clustsim_cs"$cs"_t"$thresh"_"$out_name"_pos.nii.gz
        3dmerge \
          -dxyz=1 -1clust 1 "$cs" -2clip -100000000 "$thresh" \
          -prefix lme__seeds_"$time"_clustsim_cs"$cs"_t"$thresh"_"$out_name"_pos_abstract_low.nii.gz \
          lme_abstract_low_"$time".nii.gz
        # Negative activity
#        rm lme__seeds_"$time"_clustsim_cs"$cs"_t"$thresh"_"$out_name"_neg.nii.gz
        3dmerge \
          -dxyz=1 -1clust 1 "$cs" -2clip -"$thresh" 100000000 \
          -prefix lme__seeds_"$time"_clustsim_cs"$cs"_t"$thresh"_"$out_name"_neg_abstract_low.nii.gz \
          lme_abstract_low_"$time".nii.gz
        # end
#      done
    done
    # Now merge all
    rm lme__seeds_"$time"_clustsim_cs_all_thresh_all.txt
#    for out_name in $out_names
#    do
      for sign in pos neg
      do
      rm lme__seeds_"$time"_clustsim_cs_all_thresh_all_"$out_name"_"$sign"_"$time".nii.gz
      echo "#######################################################" lme__seeds_"$time"_clustsim_cs_all_thresh_all_"$out_name"_"$sign"_abstract_low.nii.gz >> lme__seeds_"$time"_clustsim_cs_all_thresh_all_abstract_low.txt
      3dmerge -nozero \
        -gnzmean \
        -prefix lme__seeds_"$time"_clustsim_cs_all_thresh_all_"$out_name"_"$sign"_abstract_low.nii.gz \
        lme__seeds_"$time"_clustsim_cs*_t?.??_"$out_name"_"$sign"_abstract_low.nii.gz  2>> lme__seeds_"$time"_clustsim_cs_all_thresh_all_abstract_low.txt
      done
   # done
    # Make zero slugs
#    slugs=`cat lme__seeds_"$time"_clustsim_cs_all_thresh_all.txt | grep -B 4 "will not write" | grep "#######################################################" | awk '{print $2}'`
#    for slug in $slugs
#    do
#      3dcalc \
#      -a lme__seeds_"$time"_clustsim.nii.gz \
#      -expr 'a*0' \
#      -prefix $slug
#    done
  done
  # Combine pos and neg maps and color code correctioly
  # lme_names="lme_production"
fi

