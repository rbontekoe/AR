cat image_ls | while read line || [[ -n $line ]];
do
    #microk8s ctr images rm $line
    echo $line
done;
