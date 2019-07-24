" Leader mapping here does not working right
" let g:mapleader=","

map <Leader>te :tabedit <c-r>=expand("%:p:h")<cr>/
map <LocalLeader>te :tabedit <c-r>=expand("%:p:h")<cr>/

if dein#tap('caw.vim')
	function! InitCaw() abort
		if ! &l:modifiable
			silent! nunmap <buffer> <Leader>V
			silent! xunmap <buffer> <Leader>V
			silent! nunmap <buffer> <Leader>v
			silent! xunmap <buffer> <Leader>v
			silent! nunmap <buffer> gc
			silent! xunmap <buffer> gc
			silent! nunmap <buffer> gcc
			silent! xunmap <buffer> gcc
		else
			xmap <buffer> <Leader>V <Plug>(caw:wrap:toggle)
			nmap <buffer> <Leader>V <Plug>(caw:wrap:toggle)
			xmap <buffer> <Leader>v <Plug>(caw:hatpos:toggle)
			nmap <buffer> <Leader>v <Plug>(caw:hatpos:toggle)
			nmap <buffer> gc <Plug>(caw:hatpos:toggle)
			xmap <buffer> gc <Plug>(caw:hatpos:toggle)
			nmap <buffer> gcc <Plug>(caw:prefix)
			xmap <buffer> gcc <Plug>(caw:prefix)
		endif
	endfunction
	autocmd MyAutoCmd FileType * call InitCaw()
	call InitCaw()
endif

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => lightline
" wombat etc, check https://github.com/itchyny/lightline.vim
" :h g:lightline.colorscheme
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
let g:lightline={
      \ 'colorscheme': 'PaperColor',
      \ }

let g:lightline={
      \ 'colorscheme': 'PaperColor',
      \ 'active': {
      \   'left': [ ['mode', 'paste'],
      \             ['fugitive', 'readonly', 'filename', 'modified'] ],
      \   'right': [ [ 'lineinfo' ], ['percent'] ]
      \ },
      \ 'component': {
      \   'readonly': '%{&filetype=="help"?"":&readonly?"🔒":""}',
      \   'modified': '%{&filetype=="help"?"":&modified?"+":&modifiable?"":"-"}',
      \   'fugitive': '%{exists("*fugitive#head")?fugitive#head():""}'
      \ },
      \ 'component_visible_condition': {
      \   'readonly': '(&filetype!="help"&& &readonly)',
      \   'modified': '(&filetype!="help"&&(&modified||!&modifiable))',
      \   'fugitive': '(exists("*fugitive#head") && ""!=fugitive#head())'
      \ },
      \ 'separator': { 'left': ' ', 'right': ' ' },
      \ 'subseparator': { 'left': ' ', 'right': ' ' }
      \ }


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => airline
" https://github.com/vim-airline/vim-airline-themes
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Enable the list of buffers
let g:airline#extensions#tabline#enabled=1
" Show just the filename
let g:airline#extensions#tabline#fnamemod=':t'
let g:airline#extensions#whitespace#enabled=1

let g:airline_powerline_fonts=1
" let g:airline_theme='atomic'
" let g:airline_theme='badwolf'
" let g:airline_theme='silver'
" let g:airline_theme='ayu_mirage'
" let g:airline_theme='tomorrow'
let g:airline_theme='papercolor'

let g:tmuxline_powerline_separators=1
" let g:tmuxline_separators={
"     \ 'left' : '',
"     \ 'left_alt': '',
"     \ 'right' : '',
"     \ 'right_alt' : '',
"     \ 'space' : ' '}


" set background=light
set background=dark

" colorscheme hemisu

" colorscheme noctu

" colorscheme summerfruit256

colorscheme PaperColor
let g:PaperColor_Theme_Options = {
      \ 	'theme': {
      \ 		'default': {
      \ 			'transparent_background': 0
      \ 		}
      \ 	}
      \ }

" colorscheme peaksea

let ayucolor="light"  " for light version of theme
" let ayucolor="mirage" " for mirage version of theme
" let ayucolor="dark"   " for dark version of theme
" colorscheme ayu

" let g:solarized_visibility="normal" " one of "normal" (default), "low", "high";
" let g:solarized_diffmode="normal"   " one of "normal" (default), "low", "high";
" let g:solarized_termtrans=0         " make terminal background transparent if set to 1 (default: 0);
"
" The following options were not available in the original Solarized:
"
" let g:solarized_statusline="normal" " one of "normal" (default), "low" or "flat";
" let g:solarized_italics=1           " set to 0 to suppress italics (default is 1).
" let g:solarized_old_cursor_style=0  " set to 1 if you want to use the original Solarized's cursor style (default: 0). By default, the cursor is orange/red in light themes, and blue in dark themes (but please note that your terminal may override the cursor's color).
" let g:solarized_use16=0             " set to 1 to force using your 16 ANSI terminal colors.
" let g:solarized_extra_hi_groups=0   " set to 1 to enable Solarized filetype-specific syntax highlighting groups (default is 0). Please be aware that there is a long standing issue with syntax items defined in color schemes.
"
" colorscheme solarized8_high " high-contrast variant
" colorscheme solarized8      " the default Solarized theme
" colorscheme solarized8_low  " low-contrast variant
" colorscheme solarized8_flat " flat variant

let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"
