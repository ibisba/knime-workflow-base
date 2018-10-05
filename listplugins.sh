dir=$1
find ./$dir/*/settings.xml -exec python listplugins.py {} \; | sort -u | tr '\n' ','
