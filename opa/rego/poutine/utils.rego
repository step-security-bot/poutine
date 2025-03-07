package poutine.utils

import rego.v1

unpinned_github_action(purl) if {
	startswith(purl, "pkg:githubactions/")
	contains(purl, "@")
	not regex.match("@[a-f0-9]{40}", purl)
}

unpinned_docker(purl) if {
	startswith(purl, "pkg:docker/")
	not contains(purl, "@")
	not regex.match("@sha256:[a-f0-9]{64}", purl)
}

unpinned_purl(purl) if {
	unpinned_github_action(purl)
} else if {
	unpinned_docker(purl)
}

find_pr_checkouts(workflow) := xs if {
	xs := {{"job_idx": j, "step_idx": i, "workflow": workflow} |
		s := workflow.jobs[j].steps[i]
		startswith(s.uses, "actions/checkout@")
		contains(s.with_ref, "${{")
	} | {{"job_idx": j, "step_idx": i, "workflow": workflow} |
		s := workflow.jobs[j].steps[i]
		regex.match("gh pr checkout ", s.run)
	}
}

workflow_steps_after(options) := steps if {
	steps := {{"step": s, "job_idx": options.job_idx, "step_idx": k} |
		s := options.workflow.jobs[options.job_idx].steps[k]
		k > options.step_idx
	}
}

filter_workflow_events(workflow, only) if {
	workflow.events[_].name == only[_]
}

job_uses_self_hosted_runner(job) if {
	run_on := job.runs_on[_]
	not contains(run_on, "$") # skip expressions
	not regex.match(
		"(?i)^((ubuntu-((18|20|22)\\.04|latest)|macos-(11|12|13|latest)(-xl)?|windows-(20[0-9]{2}|latest)|(buildjet|warp|)-[a-z0-9-]+))$",
		run_on,
	)
}

empty(xs) if {
	xs == null
} else if {
	count(xs) == 0
}
