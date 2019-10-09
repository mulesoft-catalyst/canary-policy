zipedit(){
    curdir=$(pwd)
    unzip "$1" "$2" -d /tmp
    cd /tmp
    sed -i'.original' "s/\(implementation.host=\)\(.*\)/\1#[flowVars.host != null ? flowVars.host : '\2']/"  "/tmp/$2" && zip --update -y "$curdir/$1"  "$2"
    rm -f "$2"
    cd "$curdir"
}
