BASE=$(dirname $(realpath -s $0))/..

# copy sandbox option presets
for file in $BASE/Contents/mods/OmiChat/media/lua/shared/OmiChat/SandboxPreset/*
do
    fname=$(basename -- "$file")
    outfile="$BASE/docs/sandbox-presets/${fname%.*}.txt"
    echo -e "OmiChat = {\n$(sed -e '1d' $file)" > $outfile
done
