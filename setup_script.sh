# parameters
work_name="GitTutorialWorkDir"
data_server="mkk@127.0.0.1"
dir_on_data_server="$HOME/$work_name/SERVER/"
github_repo="git@github.com:EmeEmu/test_repo.git"


# ======= Local setup =======

# record the directory of the script
scr_dir=$(pwd)

# set the path to the working directory and make it
work_dir=$HOME/$work_name
mkdir -p $work_dir
echo "Working directory: $work_dir"

# got to the working directory and create a new git repository
cd $work_dir
mkdir main_repo
cd main_repo
git init
git branch -M main

# setup git-annex
git annex init "main_repo"

# setup gitattributes
echo "* annex.largefiles=largerthan=100kb" > .gitattributes
echo "*.txt annex.largefiles=nothing" >> .gitattributes
echo "*.png annex.largefiles=anything" >> .gitattributes
git add .gitattributes
git commit -m "Add .gitattributes file to track large files with git-annex"

# parametrize git annex
git annex config --set annex.numcopies 2
git config annex.sshcaching true

# put some data in the repo
mkdir images
cp $scr_dir/Images/exposition.png images/
echo "On a misterious island far far away, unbelivable events were about to unravel which no one could have expected ..." >> exposition.txt
git annex add *
git commit -m "Add exposition image and text"


# ======= Data server setup =======
echo "Setting up data server at $data_server:$dir_on_data_server"

# create the directory on the data server
ssh $data_server "mkdir -p $dir_on_data_server"

# setup a bare git repository on the data server + git annex
ssh $data_server "cd $dir_on_data_server && git init --bare repo_data.git && cd repo_data.git && git branch -M main && git annex init 'data_server' && git annex wanted . standard && git annex group . backup"

# connect the data server as a remote
git annex initremote data_server type=git location=ssh://$data_server$dir_on_data_server/repo_data.git autoenable=true
git annex wanted . standard
git annex group . manual
git annex sync data_server --content


# ======= Github setup =======
git remote add origin $github_repo
git config remote.origin.annex-ignore true
git push origin main git-annex


# ======= Backup setup =======
# create a backup directory
backup_dir=$HOME/$work_name/BACKUP/
mkdir -p $backup_dir
cd $backup_dir
git clone --bare $work_dir/main_repo main_repo_backup.git
cd main_repo_backup.git

# setup git annex
git annex init "backup"

# connect the backup as a remote
cd $work_dir/main_repo
git remote add backup $backup_dir/main_repo_backup.git
git annex sync backup --content
