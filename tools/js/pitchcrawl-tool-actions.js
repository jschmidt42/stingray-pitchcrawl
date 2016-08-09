define(['common/file-system-utils',
	'services/host-service',
	'services/project-service'], function (fileUtils, hostService, projectService) {

	function openInSublime() {
		return projectService.getCurrentProjectPath().then(function (projectPath) {
			return fileUtils.join(projectPath, "pitchcrawl.sublime-project")
		}).then(function (sublimeProjectFilePath) {
			return hostService.startProcess('C:/Program Files/Sublime Text 3/sublime_text.exe', [sublimeProjectFilePath]);
		});
	}

	return {
		openInSublime
	};
});
