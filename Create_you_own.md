This file contains a step-by-step tutorial of how to create a code+data git system for you own research needs.

# Setup

## Local Setup

On your working computer, we'll start by creating a repository. (we will also change the name of the branch to comply with GitHub's naming convention)
```bash
mkdir my_repo
cd my_repo
git init
git branch -M main
```

We will then initialize git-annex with the label `main_repo`. This label will be usefull when we want to identify where we can find different versions of the data
```bash
git annex init "main_repo"
```

Files can now be added to the repository. Code files should be added using `git add` and data files should be added using `git annex add`.  
Once the files are added, we can commit them to the repository. 
```bash
git commit -m "Initial commit with data files tracked by git-annex"
```

## GitHub Setup

Let's start by adding GitHub as a remote. Since GitHub is not well suited to store large data files, we will exclude the annexed data from being pushed there.
```bash
git remote add github git@github.com:username/my_repo.git
git config remote.github.annex-ignore true
```

We can now push our initial commit to GitHub
```bash
git push github main
```

## Backup Setup

Now we will create a backup repository on an external disk mounted at `/mnt/backup_drive`. This backup will be used to store a copy of both the data files and the code files.  
```bash
cd /mnt/backup_drive
git clone /path/to/my_repo my_repo_backup
cd my_repo_backup
git annex init "backup"
```
Now back in our local repository, we will add the backup as a remote, and we will sync the 2 repositories.
```bash
git remote add backup /mnt/backup_drive/my_repo_backup
git annex sync backup --content
```















We will now add a remote for the data repository. This repository will be used to store the data files. Here we give an example for a remote server accessible through ssh.  
First ssh into the server and create a new repository.
```bash
ssh username@server
server$ mkdir my_repo_data.git
server$ cd my_repo_data.git
server$ git init --bare
```
Then go back to your local computer and add the remote
```bash
git remote add data_server username@server:/path/to/my_repo_data.git
```
Now we can push the data files to the data repository
```bash
git push data_server main
git annex sync data_server --content
```
