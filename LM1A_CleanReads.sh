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
#Inputs: Raw Seqsnp .bz2 files
#      : ${cross}_SRA_files.txt (e.g. QB_SRA_files.txt). Format: name\t$fq_name_R1.fq

#Function: Uses IlluQC.pl from NGSQCToolkit_v2.3.3 and trimmomatic/0.39 to clean raw seqsnp reads

#Output: $fq_name_R1.fq_filtered.trimmo.paired.gz (note these aren't actually paired reads)

dat=$(date +%Y_%m_%d);
slurm_scripts="/home/b.bssc1d/scripts/reusable_slurm_pipeline";
raw_data="/scratch/b.bssc1d/Linkage_Mapping/Raw_SeqSNP_Data";

#cross="QA"
cross="QB";
#cross="QCE";

dir="/scratch/b.bssc1d/Linkage_Mapping/LM1_${cross}"; 
qx_names="/home/b.bssc1d/scripts/S1_QTL/${cross}_SRA_files.txt"; 
this_step="/scratch/b.bssc1d/Linkage_Mapping/${cross}_LM1A_Progress.txt";

perl $slurm_scripts/list_delete.pl $qx_names $this_step Step_LM_1A_Complete $dat.LM1ToDo

parallel -N 1 -j 30 --colsep '\t' --delay 0.2 "echo {1} $dat Started >> $this_step && bzip2 -d $raw_data/{1}.bz2; perl ~/bin/NGSQCToolkit_v2.3.3/QC/IlluQC.pl -se $raw_data/{1} 1 A -l 70 -s 20 -t 1 -z g -o $dir && java -jar $TRIMMOMATIC SE $dir/{1}_filtered.gz $dir/{1}_filtered.trimmo.paired.gz SLIDINGWINDOW:4:15 MINLEN:70 && echo {1} $dat Step_LM_1A_Complete >> $this_step" :::: $qx_names.del.$dat.LM1ToDo;
