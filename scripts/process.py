import iff2raw

def main():
    input_path = "C:\\MyProjects\\PT1210\\gfx"
    output_path = "C:\\MyProjects\\PT1210\\legacy\\gfx"

    # process cut list
    iff2raw.process_cut_list("hud-cut-list.yaml", "hud.iff", input_path, output_path)

    # grab task document and parse the tasks
    iff2raw.process_task_list("tasks.yaml", input_path, output_path)
        
if __name__ == "__main__":
    main()

