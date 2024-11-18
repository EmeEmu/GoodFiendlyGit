This file contains a step-by-step tutorial of how to create a code+data git+git-annex system for you own research needs.

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

Now lets configure `git-annex` to make usage easier with this repository.  
We will start by explaining to `git` and `git-annex` which files should be added to `git` and which ones should be added to `git-annex`. This can be done through the `.gitattributes` file. For now lets say that any files larger than 100kb as well as every file with extention `.png` should be added to `git-annex`, while every file with the extention `.txt` should be added to git. (For a complete set of examples on how to set this up, have a look at [this page](https://manpages.ubuntu.com/manpages/jammy/man1/git-annex-matching-expression.1.html) and [this page](https://git-annex.branchable.com/tips/largefiles/))  
To do this, create a `.gitattributes` file in the root of the repository with the following content
```git
# in the .gitattributes file
* annex.largefiles=largerthan=100kb
*.txt annex.largefiles=nothing
*.png annex.largefiles=anything
```
Let's now add + commit this file:
```bash
git add .gitattributes
git commit -m "Add .gitattributes file to track large files with git-annex"
```


As we are paranoid about loosing data, we will also configure `git-annex` to store 2 copies of the data files at all times. This means that `git-annex` will check if 2 copies of a file are already stored in remotes before this file can be droped from the current repository. This can be done with the following command
```bash
git annex config --set annex.numcopies 2
```

We will also enable ssh caching :
```bash
git config annex.sshcaching true
```

Files can now be added to the repository. In principle, we should use `git add` or `git annex add` based on file content, for example code files should be added using `git add` and data files should be added using `git annex add`. However, as we have set the `annex.largefiles` configuration, `git add` will automatically use `git annex add` for files that match the criteria. (there are a few subtleties with this. We'll talk about them later but you can read [this](https://git-annex.branchable.com/tips/largefiles/), [this](https://git-annex.branchable.com/forum/Using___39__git_add__39___in_mixed_content_repository__63__/), and [this](https://git-annex.branchable.com/tips/unlocked_files/) for discussions on those subtleties.)  
Once the files are added, we can commit them to the repository. 
```bash
git commit -m "Initial commit with data files tracked by git-annex"
```

## Remote server setup for data

Let's create a remote repository on an external server where `git-annex` will keep the data files. This will be setup using the `git-annex` [special remotes][https://git-annex.branchable.com/special_remotes/] feature. In particular we are going to use a [git special remote](https://git-annex.branchable.com/special_remotes/) over SSH as it doesn't require any other software. However, other types of special remotes are available, and for large datasets transfered over SSH the [rsync spacial remote](https://git-annex.branchable.com/special_remotes/rsync/) might be more appropriate.

Start by logging into the server using SSH, then create a new git repository (notice it is a bare repository, hence the `.git` in the name) :
```bash
server$ git init --bare /path/to/my_repo_data.git
server$ cd /path/to/my_repo_data.git
server$ git branch -M main
server$ git annex init "data_server"
```
Now let's configure this repository to specify how it should handle the `git-annex` data. Indeed if we want this repo to keep all the versions of all the files (even the deleted ones) it is possible through `git-annex`'s [preferred_content](https://git-annex.branchable.com/preferred_content/), and a bunch of standard configurations are available [here](https://git-annex.branchable.com/preferred_content/standard_groups/). We will use the standard `backup` configuration where "All content is wanted. Even content of old/deleted files" :
```bash
server$ git annex wanted . standard
server$ git annex group . backup
```
The server is now setup. Let's go back to the repo on our personal machine. We'll start by telling this repo about the remote on the server and give it the name `data_server`:
```bash
git annex initremote data_server type=git location=ssh://user@server_ip:/path/to/my_repo_data.git autoenable=true
```
Notice that we have autoenabled this spacial remote so that every clone of the main repo will automatically be able to use it.

We'll also take the time to setup the prefered content on this local repo so that the user can choose which data files are required on the go :
```bash
git annex wanted . standard
git annex group . manual
```

And now we can sync the 2 repos: **?Unsure why --content is needed here? The prefered content from the data_server should auto-pull the content it doesn't have no ?**
```bash
git annex sync data_server --content
```

## GitHub Setup

Let's add GitHub as a remote for the repo. You first have to create an empty repo on the GitHub website.  
Since GitHub is not well suited to store large data files, we will exclude the annexed data from being pushed there.
```bash
git remote add origin git@github.com:username/my_repo.git
git config remote.origin.annex-ignore true
```

We can now push our initial commit to GitHub
```bash
git push origin main git-annex
```

## Backup Setup

Now we will create a backup repository on an external disk mounted at `/mnt/backup_drive`. This backup will be used to store a copy of both the data files and the code files.  
```bash
cd /mnt/backup_drive
git clone --bare /path/to/my_repo my_repo_backup.git
cd my_repo_backup.git
git annex init "backup"
```
Now back in our local repository, we will add the backup as a remote, and we will sync the 2 repositories.
```bash
git remote add backup /mnt/backup_drive/my_repo_backup
git annex sync backup --content
```






# Usage

## Second user

If you or a collaborator want to use the repository on another computer, you can clone the repository from GitHub.  
```bash
git clone git@github.com:username/my_repo.git
cd my_repo
```

This will download the code files and the symlinks of data files, but not the datafiles themselves. To get the data files, we need to initialize `git-annex` and syncronize the repository with the data_server.
```bash
git annex init "second_user"
git config annex.sshcaching true
git config remote.origin.annex-ignore true
git annex sync
```
As you can see we initialized `git-annex` with the label `second_user`, this is not mendatory but is usefule to keep track of which user has a copy of which data file. This is usefull to know who has the data files on their computer and who doesn't. We also enabled ssh caching for faster access to the data_server (again this is not mendatory). And we specified to the repo not to send annex data to GitHub.   
Even tho we havn't explained to this repo where to find the data, it already knows about the `data_server` thanks to the `autoenable=true` option we used when creating the `data_server` special remote. This user will therefore be able to `git annex get <file>` any file.





# Submodules

## Adding a submodule to an existing repo
```bash
git submodule add git@github.com:username/my_submodule.git
git commit -am "Add submodule my_submodule"
git push origin main
```

## Cloning a repo with submodules
```bash
git clone --recurse-submodules git@github.com:username/my_repo.git
```

If you forgot to use `--recurse-submodules` when cloning, you can still get the submodules with
```bash
git submodule update --init --recursive
```

## Pulling changes containing submodule addition(s)
If a collaborator adds a submodule to the repo, you will need to pull the changes and then update the submodules
```bash
git pull
git submodule update --init --recursive
```

## Updating a submodule
By default, a submodule is in a detached HEAD state. To update the submodule to the latest commit on its `main` branch, you can do
```bash
git submodule update --remote my_submodule
git commit -am "Update submodule my_submodule"
```

## Modifying a submodule from the main repo
While working on `my_repo`, you might need to make changes to `my_submodule`. To do so, you need to navigate to the submodule directory and work from there. However, the submodule is in detatched state by default, so in order to track modifications you'll need to checkout a branch (here will'll work on the `main` branch of `my_submodule)`).
```bash
cd my_submodule
git checkout main
```
Now we need to explain to git what to do when the submodule is modified. First we'll perform a merge in case there are modifications on the remote which we don't have localy.
```bash
cd ..
git submodule update --remote --merge my_submodule
```
Now we can go back to the submodule directory and make our modifications. Once we are done, we can commit the changes and push them to the submodule's remote.
```bash
cd my_submodule
# make changes
git commit -am "Update submodule"
git push origin main
```
WARNING : If changes were made on the remote of the submodule in the mean time, this might cause problems. Please refer to [this page (section : Working on a Submodule)](https://git-scm.com/book/en/v2/Git-Tools-Submodules) if this risk exists in your workflow, or if you add a problem and want a solution.  

Now let's go back to the main repo and commit the changes to the submodule.
```bash
cd ..
git push --recurse-submodules=check
```

Alternatively, you can also modify and commit (but not push) in the submodule, and then push from `my_repo` with
```bash
git push --recurse-submodules=on-demand
```





