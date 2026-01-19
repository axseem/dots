function aic -d "Compose AI context modules"
    set -l ai_dir ~/.config/ai

    if test (count $argv) -eq 0
        echo "Usage: aic <module> [module...]"
        echo "Available modules:"
        for f in $ai_dir/*.md
            echo "  "(basename $f .md)
        end
        return 1
    end

    for mod in $argv
        set -l file $ai_dir/$mod.md
        if test -f $file
            cat $file
            echo -e "\n---\n"
        else
            echo "Module not found: $mod" >&2
        end
    end
end
