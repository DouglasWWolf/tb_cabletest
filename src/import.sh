for filename in *.v; do
   remotefn=/fpga/sidewinder_cabletest/src/$filename
   if [ -f $remotefn ]; then
       echo Copying $filename
       cp $remotefn .
   fi
done
