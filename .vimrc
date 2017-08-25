"Ctrl+p : complete the word
"Ctrl+] : find the definition of an element, such as variable, function
"Ctrl+t : return
"
"in minibuf you can use Tab to switch window
"
"Find something among multiple files, :Rgrep strings which are found
"
"avoid bugs from older version of vi
set nocompatible

"color scheme
colorscheme darkblue

"display the number of lines
set nu

"detect file type
filetype on
filetype plugin indent on
set completeopt=longest,menu

"indent format
set shiftwidth=4

"highlight search
set hlsearch

"set Tab format
  "Only do this part when compiled with support for autocommands.
"if has("autocmd")
"    " Use filetype detection and file-based automatic indenting.
"    filetype plugin indent on
"
"    " Use actual tab chars in Makefiles.
"    autocmd FileType make set tabstop=8 shiftwidth=8 softtabstop=0 noexpandtab
"endif
" For everything else, use a tab width of 4 space chars.
set tabstop=4       " The width of a TAB is set to 4.
                    " Still it is a \t. It is just that
                    " Vim will interpret it to be having
                    " a width of 4.
set shiftwidth=4    " Indents will have a width of 4.
set softtabstop=4   " Sets the number of columns for a TAB.
set expandtab       " Expand TABs to spaces.
set autoindent
set cindent


"set shortcut keys for splitted window switching
map <C-h> <C-W>h
map <C-j> <C-W>j
map <C-k> <C-W>k
map <C-l> <C-W>l

map <F9> :call MakeFile()<CR>
func! MakeFile()
    exec ":wall"
    exec ":make"
endfunc

"save all opened files
map <F3> :wall<CR>

map <F4> :quitall<CR>


"-------------------------Taglist Plugin-----------------
"configure Taglist
"only display tags of the current file
let Tlist_Show_One_File = 1
"items in tags are sorted by name
let Tlist_Sort_Type = "name"

"make tag
map <F10> :call MakeTag()<CR><CR>
func! MakeTag()
    exec ":wall"
    exec "!ctags -R --c++-kinds=+p --fields=+iaS --extra=+q"
    exec "!cscope -Rbq"
    cs add cscope.out
endfunc


"-------------------------WinManager Plugin-----------------
"configure WinManager plugin
let g:winManagerWindowLayout='FileExplorer|TagList'
let g:winManagerWidth = 30
map <F8> :WMToggle<CR>


"------------------------miniBufExpl---------------------------
"<C-Tab> <C-S-Tab> to switch buffer and open it in current window
let g:miniBufExplMapCTabSwitchBufs = 1
"<c-导航键>to switch buffer and open it in current window
let g:miniBufExplMapWindowNavVim = 1


"-------------------------Cscope Plugin-----------------
set cscopequickfix=s-,c-,d-,i-,t-,e-

map <F7> :cw<CR>

if filereadable("cscope.out")
    cs add cscope.out
endif

"move the cursor to the word which you want to find, then press <F6>
"+s|g|c|t|e|f|i|d
"s: find symbol
"g: find definition
"c: find functions which call the function pointed by the cursor
"t: find string
"e:
"f: find file
"i: find files including the file pointed by the cursor
"d: find functions called by the function pointed by the cursor
nmap <F6>s :cs find s <C-R>=expand("<cword>")<CR><CR>
nmap <F6>g :cs find g <C-R>=expand("<cword>")<CR><CR>
nmap <F6>c :cs find c <C-R>=expand("<cword>")<CR><CR>
nmap <F6>t :cs find t <C-R>=expand("<cword>")<CR><CR>
nmap <F6>e :cs find e <C-R>=expand("<cword>")<CR><CR>
nmap <F6>f :cs find f <C-R>=expand("<cfile>")<CR><CR>
nmap <F6>d :cs find d <C-R>=expand("<cword>")<CR><CR>


"-------------------------A Plugin-----------------
"can swift from cpp to h or from h to cpp
"map <F9> :A<CR>


"move to top window
map <F5> <C-w>t

"set the size of a window to 8 lines
map <F2>8 14<C-w>_

"maximum the size of a window
map <F2>m <C-w>_

"you can change tags to your source code
if filereadable("tags")
    set tags=tags
elseif filereadable("../tags")
    set tags=../tags
else
    "echo "no tags"
endif

"add other tags
set tags+=/home/qiangzhou/Android/Sdk/ndk-bundle/platforms/android-21/arch-arm64/tags
set tags+=/home/qiangzhou/ext_disk/Work/asr-android6/vendor/asr/asr-camera-core/tags
"add system api tags
set tags+=~/.vim/systags

"large file min size ,MB
let g:LargeFile=100
