#!/bin/bash --login
#SBATCH -o /scratch/b.bssc1d/Linkage_Mapping/logs/LM_2.%A.out.txt
#SBATCH -e /scratch/b.bssc1d/Linkage_Mapping/logs/LM_2.%A.err.txt
#SBATCH --ntasks=30
#SBATCH --time=10:00:00
#SBATCH --mem-per-cpu=4G
#SBATCH --partition=htc
#SBATCH --mail-user=daniel.wood@bangor.ac.uk
#SBATCH --mail-type=ALL 

#Requirements: reusable slurm pipeline, modules listed below

module load parallel
module load samtools
module load bwa

#Inputs: cleaned reads from step LM1A
#        progress.txt file from LM1A

#Output: .bam files from mapping to genome using bwa-mem, reads with MAPQ<20 removed. 

genome="/scratch/b.bssc1d/6Pop_Resequencing/TGS_GC_fmlrc.scaff_seqs.fa";
dat=$(date +%Y_%m_%d); #store date as variable

#Leave one of these per cross uncommented
#cross="QA";
cross="QB";
#cross="QCE";

dir="/scratch/b.bssc1d/Linkage_Mapping/LM1_${cross}"; #Set output directory (one per cross)
this_step="/scratch/b.bssc1d/Linkage_Mapping/${cross}_LM_2_Progress.txt"; #Set progress file (one per cross)
qx_names="/home/b.bssc1d/scripts/S1_QTL/${cross}_SRA_files.txt"; #Get list of file names (one per cross)
previous_step="/scratch/b.bssc1d/Linkage_Mapping/${cross}_LM1A_Progress.txt"; #Progress file from previous step, LM1A

#list_keepdelete.pl takes i) progress file from previous step, and ii) progress file from the current step and outputs a new file (saved in the $names variable below) which has the files that have passed the previous step, but not yet passed the current step.
#For more details see https://github.com/danielwood1992/reusable_slurm_pipeline 
perl ~/scripts/Linkage_Mapping/list_keepdelete.pl $qx_names $previous_step Step_LM_1A_Complete $this_step LM_2_Complete $dat.LM2ToDo;
names=$qx_names.kdel.$dat.LM2ToDo; 

#These two lines are sometimes needed if parallel outputs too many temporary files.
TMPDIR="/scratch/b.bssc1d/temp_parallel";
export TMPDIR;


parallel --colsep "\t" -j 15 --delay 0.2 --tmpdir /scratch/b.bssc1d/ "echo {1} $dat Started >> $this_step && bwa mem -t 2 $genome $dir/{1}_filtered.trimmo.paired.gz | samtools fixmate -m - -  | samtools sort - | samtools view -q 20 -o $dir/{1}.bwa.sorted.bam - && samtools index $dir/{1}.bwa.sorted.bam && echo {1} $dat LM_2_Complete >> $this_step && echo done" :::: $names; 

#See LM1A for explanation of gnu parallel. Command within the double quotes is performed in parallel.
#This step i) uses bwa mem (2 threads) to map reads to genome [note these are single reads, not pairs]. "|" is used to pipe the STDOUT of a command (a sam file in this case) to the STDIN of the next command. Google samtools for how each specific step takes STDIN and outputs STDOUT. These steps then ii) fix the mate pairs, can't really remember why you do this, iii) sorts the reads by leftmost coordinate, iv) removes those with MAPQ<20 and outputs to a bam file (compressed sam). Command after && then prints a line indicating this step is complete for this particular input file and appends it to $this_step, which will be used by list_keepdelete.pl when you next run this script.

