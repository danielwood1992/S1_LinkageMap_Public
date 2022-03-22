#!/bin/bash --login
#SBATCH --partition=compute
#SBATCH --ntasks=30
#SBATCH --time=12:00:00
#SBATCH -o /scratch/b.bssc1d/Linkage_Mapping/logs/LM_1A_%A.out.txt
#SBATCH -e /scratch/b.bssc1d/Linkage_Mapping/logs/LM_1A_%A.err.txt
#SBATCH --mail-user=daniel.wood@bangor.ac.uk
#SBATCH --mail-type=ALL

export PERL5LIB=~/perl5/lib/perl5/
module add FastQC/0.11.8
module add trimmomatic/0.39
module load parallel

#Requirements: reusable_slurm_pipelne
#	       modules loaded above
#Inputs: Raw Seqsnp .bz2 files
#      : ${cross}_SRA_files.txt (e.g. QB_SRA_files.txt). Format: name\t$fq_name_R1.fq

#Function: Uses IlluQC.pl from NGSQCToolkit_v2.3.3 and trimmomatic/0.39 to clean raw seqsnp reads

#Output: $fq_name_R1.fq_filtered.trimmo.paired.gz (note these aren't actually paired reads)

dat=$(date +%Y_%m_%d); #stores the date as a variable
slurm_scripts="/home/b.bssc1d/scripts/reusable_slurm_pipeline";
raw_data="/scratch/b.bssc1d/Linkage_Mapping/Raw_SeqSNP_Data";

#Uncomment one of these per cross
#cross="QA"
cross="QB";
#cross="QCE";

dir="/scratch/b.bssc1d/Linkage_Mapping/LM1_${cross}"; #Output directory
qx_names="/home/b.bssc1d/scripts/S1_QTL/${cross}_SRA_files.txt"; #Input sample\tfastq list 
this_step="/scratch/b.bssc1d/Linkage_Mapping/${cross}_LM1A_Progress.txt"; #Text file recording progress

#list_delete.pl gets a list of files to run from i) the complete list of files to do and ii) the progress file for this step which records which files have already been completed. Removes the completed files from the list of files.

#Output will be $qx_names.del.$dat.LM1ToDo;

#See https://github.com/danielwood1992/reusable_slurm_pipeline for details
perl $slurm_scripts/list_delete.pl $qx_names $this_step Step_LM_1A_Complete $dat.LM1ToDo

parallel -N 1 -j 30 --colsep '\t' --delay 0.2 "echo {1} $dat Started >> $this_step && bzip2 -d $raw_data/{1}.bz2; perl ~/bin/NGSQCToolkit_v2.3.3/QC/IlluQC.pl -se $raw_data/{1} 1 A -l 70 -s 20 -t 1 -z g -o $dir && java -jar $TRIMMOMATIC SE $dir/{1}_filtered.gz $dir/{1}_filtered.trimmo.paired.gz SLIDINGWINDOW:4:15 MINLEN:70 && echo {1} $dat Step_LM_1A_Complete >> $this_step" :::: $qx_names.del.$dat.LM1ToDo;

#parallel -N 1 -j 30 --colsep '\t' --delay 0.2 "some command -i {1}" :::: $list_of_things - runs gnu parallel: takes lines from the file specified after the :::: and runs the command within double quotes in parallel. {1} here refers to the first field of the line (split here by \t). Google "gnu parallel command line options" and have a read - in most cases though an array job will be more appropriate.
#A series of commands separated by ; (just run one then the next one) or && (run the next one only if the previous is complete)
#echo whatever >> $a_file: appends "whatever" to file specifie by $a_file
#This step i) unzips the files, then runs the IlluQC.pl script from NGSQCToolkit: cleans the reads; ii) TRIMMOMATIC (cleans the output reads some more using a different method), iii) outputs "filename date Pattern_Indicating_Step_Completed" to the $this_step file that your next run of list_delete.pl will exclude from subsequent runs.


