# Authorized codebase replacement

The user requested replacing the old application with the Matlingo frontend, retaining contributor history, resetting the application database to two roles, and subsequently continuing lesson-depth development without pushing to GitHub.

The local branch refactor/matlingo-mobile-supabase starts from original main commit 967b9cb. The original 94-commit ancestry, remote branches, AGENTS.md and historical migration contents are preserved. The user-authorized replacement supersedes legacy architecture/role/commerce compatibility requirements that describe the removed runtime. No force push, new repository initialization or author-history rewrite is used.

Runtime code now lives directly in lib/, using shared app theme/layout/motion and experiments/. Historical root documentation is archived under docs/legacy/repository-root. Supabase applied SQL sources are separate from the preserved migration history; reconcile local/remote history before any CLI database deployment. Never run the destructive reset as routine CI.

No push is authorized after the user's latest instruction. Commits, plans, implementation and checks remain local until the user changes that instruction.
