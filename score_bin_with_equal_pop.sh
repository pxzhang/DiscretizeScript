if [ $# -lt 3 ]; then
    echo "Usage: sh score_bin_with_equal_pop.sh file_name #_score_field #_target_field [header_ind]"
    echo "Parameters: file_name - input file, with scores and target indicator"
    echo "            #_score_field - column number of score field"
    echo "            #_target_field - column number of target field"
    echo "            header_ind - (optional) 1: with header; 0: without header"
    exit 1
fi

input_file=$1
score_field=$2
tgt_field=$3
if [ $# -le 3 ]; then
    header_ind=1
else
    header_ind=$4
fi

cat ${input_file} | awk -F "|" -v H=${header_ind} -v SCORE=${score_field} -v TGT=${tgt_field} 'BEGIN{OFS="|";}NR>H{print $SCORE, $TGT;}' | sort -t "|" -nk 1,1 -s > ${input_file}.sort

## sample size
N=`cat ${input_file}.sort | wc -l`
### bin size
S=100

equal_freq_res=${input_file%%.*}_equal_freq.csv
equal_width_res=${input_file%%.*}_equal_width.csv

cat ${input_file}.sort | awk -F "|" -v N=${N} -v S=${S} -v SCORE=1 -v TGT=2 'BEGIN{OFS=","}
    {
        bin_idx=int((NR-2)*S/N+1);
        if(bin_idx in bin_lower) {
            bin_upper[bin_idx]=$SCORE;
        } else {
            bin_lower[bin_idx]=$SCORE;
        }
        bin_upper[bin_idx]=$SCORE;
        pop[bin_idx]++;
        tgt[bin_idx]+=$TGT;
    }
    END{
        print "binIdx,popCnt,tgtCnt,binLower,binUpper";
        for(i=1; i<=S; i++)
            print i, pop[i], tgt[i], bin_lower[i], bin_upper[i];
    }' > ${equal_freq_res} &

cat ${input_file}.sort | awk -F "|" -v S=${S} -v SCORE=1 -v TGT=2 'BEGIN{OFS=",";}{
        bin_idx=int($SCORE * S);
        if(bin_idx in bin_lower) {
            if(bin_lower[bin_idx] > $SCORE){
                bin_lower[bin_idx] = $SCORE;
            }
            if(bin_upper[bin_idx] < $SCORE){
                bin_upper[bin_idx] = $SCORE;
            }
        } else {
            bin_upper[bin_idx]=$SCORE;
            bin_lower[bin_idx]=$SCORE;
        }
        pop[bin_idx]++;
        tgt[bin_idx]+=$TGT;
    }
    END{
        print "binIdx,popCnt,tgtCnt,binLower,binUpper";
        for(i in pop)
            print i, pop[i], tgt[i], bin_lower[i], bin_upper[i];
    }' > ${equal_width_res} &

wait

rm ${input_file}.sort
