# Welcome to the example repository for the *GoodFriendlyGit* turotial!

## What is this repository for?
This repository is used to demonstrate how to use `git` and `git-annex` to version control and share both code and data in a scientific context. 
It is part of the *GoodFriendlyGit* tutorial, which is available on the [GoodFriendlyGit](https://github.com/EmeEmu/GoodFiendlyGit/tree/main) repository.

## How to clone this repository?
To clone this repository, you can use the following command:
```bash
git clone https://github.com/EmeEmu/test_repo.git
```
This will create a new directory called `test_repo` in your current working directory, which contains a copy of this repository.

However, this repository doesn't only contain text files, it also contains broken symbolic links to files that are stored on another server. This data is controled using `git-annex`.  
Let's setup the current repository to be able to access the data files.  
First we need to intialize `git-annex`. Replace `my_name` with your name. This is a label which is useful to keep track of who has a copy of the data files.
```bash
git annex init "my_name"
```

We will also configure a couple of other things :
```bash
git config annex.sshcaching true # This is to avoid to many SSH credential prompts
git config remote.origin.annex-ignore true # This is to avoid pushing the data files to GitHub by mistake.
```

Now we will sync the local annex database with the remote server :
```bash
git annex sync
```

We are all set!


## Exercice 1

For the first exercice, we will investigate the content of the repo.

Can you read the `.txt` file ?  
Can you open the `.png` image ? 

The actual image is currently stored on the server, and `.png` file that you have is actually a broken symbolic link.  
If you can get the actual image using `git-annex` by running the following command:
```bash
git annex get images/exposition.png
```
Now you should be able to open the image.

## Exercice 2

For the second exercice, go to [this link](https://github.com/EmeEmu/GoodFiendlyGit/tree/main/Images), select one of the images and dowload it.

Then move this image in the `images/` directory in the repo, create a `.txt` file in the root of the repo, and write in it a description of your image.

You should now have 2 modifications to the repo that `git` doesn't know about. You can check this with :
```bash
git status
```

To tell `git` about these modifications, you can use :
```bash
git add your_text_file.txt
git annex add images/your_image.png
```
Notice that we use `git add` for the `.txt` file and `git annex add` for the image. This is because the image is too large and we want to manage it with `git-annex` instead of `git`.

If you run `git status` again, you should see that `git` knows about the modifications. However they haven't been saved into the git tree yet. To save them, you can use :
```bash
git commit -m "Added a description and an image"
```
Idealy you want to change the message of the commit to something informative.

You can now push your changes to GitHub with :
```bash
git push origin
```
At this point you might get an error `regected ... the remote contains work that you do not have localy`. This is because someone else pushed changes to the repo while you were working on it. You can get these changes with :
```bash
git pull origin
```
And now you can push your changes again with `git push origin`.

GitHub will now have you text file and the symlinked image. However the actual image is still on your computer. To share it, you need to sync the annex with the remote server and copy it to the server :
```bash
git annex sync
git annex copy --to data_server images/your_image.png
```
(Notice, in this tutorial we are using an older version of `git annex` on the server. Hence the need for the second line. With an up to date version, and given the configuration that was done in the background, `git annex sync` would copy the image to the server automatically. This is because the server was setup to always require all the data).

At any point, if you want to know who as the actual images, you can run :
```bash
git annex whereis
```

If you want to get the actual images added by other people, you can again use :
```bash
git annex get images/their_image.png
```


## Exercice 3

In order to save disk space, you can drop the actual images from your computer. To do so, you can run :
```bash
git annex drop images/your_image.png
```
If you run this now, you will get an error saying that `git-annex can only verify the existance of 1 out of 2 necessary copies`.  
This is because, with the current configuration, we have configured behind the scene that 2 copies of each annex file should be present (somewhere) at all times. And the only 2 somewheres your current repository knows about are this repository and the server.

So let's create a local backup. This can be anywhere on you computer, even (and preferably) on another drive.

Firt get the path to you current repository (for example using `pwd`). Then go to whereever you want to create your backup, and clone the repository :
```bash
git clone --bare /path/to/your/repo repo_backup.git
```
Notice the `--bare` flag. This is because we don't want to clone the actual files, only the git history. By convention, the `.git` extension is used to name bare repositories.

Then move in the backup directory and initialize the annex :
```bash
cd repo_backup.git
git annex init "backup"
```

You can now go back to your original repository and add the backup as a remote :
```bash
cd /path/to/your/repo
git remote add backup /path/to/your/backup/repo_backup.git
git annex sync backup --content
```
This will sync the repo with the backup, sending the actual files as well as the text files.

You should now be able to drop images.

Anytime you want to backup you repo, you can use :
```bash
git annex push backup
```

