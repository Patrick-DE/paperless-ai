/**
 * Service for handling placeholder replacement in prompts
 * Used by all LLM services to ensure consistent placeholder handling
 */
class RestrictionPromptService {
  /**
   * Process placeholders in a prompt by replacing them with actual data
   * @param {string} prompt - The original prompt that may contain placeholders
   * @param {Array} existingTags - Array of existing tags
   * @param {Array|string} existingCorrespondentList - List of existing correspondents
   * @param {Object} config - Configuration object (unused but kept for compatibility)
   * @returns {string} - Prompt with placeholders replaced
   */
  static processRestrictionsInPrompt(prompt, existingTags, existingCorrespondentList, config) {
    // Replace placeholders in the original prompt
    return this._replacePlaceholders(prompt, existingTags, existingCorrespondentList);
  }

  /**
   * Build restriction instructions to prepend to the prompt when restrictions are enabled
   * This ensures the AI knows which tags/correspondents/document types are available
   * @param {Object} config - Configuration object with restriction settings
   * @param {Array} existingTags - Array of existing tags from Paperless-ngx
   * @param {Array|string} existingCorrespondentList - List of existing correspondents
   * @param {Array} existingDocumentTypes - Array of existing document types
   * @returns {string} - Restriction instructions to prepend to the prompt
   */
  static buildRestrictionPrompt(config, existingTags, existingCorrespondentList, existingDocumentTypes = []) {
    const restrictionParts = [];

    // Check if tag restrictions are enabled
    if (config.restrictToExistingTags === 'yes' || config.restrictToExistingTags === true) {
      const tagsList = this._formatTagsList(existingTags);
      if (tagsList) {
        restrictionParts.push(
          `IMPORTANT: You must ONLY use tags from this list. Do not create or suggest any tags not in this list:\nAvailable tags: ${tagsList}`
        );
      }
    }

    // Check if correspondent restrictions are enabled
    if (config.restrictToExistingCorrespondents === 'yes' || config.restrictToExistingCorrespondents === true) {
      const correspondentsList = this._formatCorrespondentsList(existingCorrespondentList);
      if (correspondentsList) {
        restrictionParts.push(
          `IMPORTANT: You must ONLY use correspondents from this list. Do not create or suggest any correspondents not in this list:\nAvailable correspondents: ${correspondentsList}`
        );
      }
    }

    // Check if document type restrictions are enabled
    if (config.restrictToExistingDocumentTypes === 'yes' || config.restrictToExistingDocumentTypes === true) {
      const docTypesList = Array.isArray(existingDocumentTypes)
        ? existingDocumentTypes.filter(dt => dt && dt.name).map(dt => dt.name).join(', ')
        : '';
      if (docTypesList) {
        restrictionParts.push(
          `IMPORTANT: You must ONLY use document types from this list. Do not create or suggest any document types not in this list:\nAvailable document types: ${docTypesList}`
        );
      }
    }

    if (restrictionParts.length > 0) {
      return '\n\n' + restrictionParts.join('\n\n') + '\n\n';
    }

    return '';
  }

  /**
   * Replace placeholders in the prompt with actual data
   * @param {string} prompt - The original prompt
   * @param {Array} existingTags - Array of existing tags
   * @param {Array|string} existingCorrespondentList - List of existing correspondents
   * @returns {string} - Prompt with placeholders replaced
   */
  static _replacePlaceholders(prompt, existingTags, existingCorrespondentList) {
    let processedPrompt = prompt;

    // Replace %RESTRICTED_TAGS% placeholder
    if (processedPrompt.includes('%RESTRICTED_TAGS%')) {
      const tagsList = this._formatTagsList(existingTags);
      processedPrompt = processedPrompt.replace(/%RESTRICTED_TAGS%/g, tagsList);
    }

    // Replace %RESTRICTED_CORRESPONDENTS% placeholder
    if (processedPrompt.includes('%RESTRICTED_CORRESPONDENTS%')) {
      const correspondentsList = this._formatCorrespondentsList(existingCorrespondentList);
      processedPrompt = processedPrompt.replace(/%RESTRICTED_CORRESPONDENTS%/g, correspondentsList);
    }

    return processedPrompt;
  }

  /**
   * Format tags list into a comma-separated string
   * @param {Array} existingTags - Array of existing tags
   * @returns {string} - Comma-separated list of tag names or empty string
   */
  static _formatTagsList(existingTags) {
    if (!Array.isArray(existingTags) || existingTags.length === 0) {
      return '';
    }

    return existingTags
      .filter(tag => tag && tag.name)
      .map(tag => tag.name)
      .join(', ');
  }

  /**
   * Format correspondents list into a comma-separated string
   * @param {Array|string} existingCorrespondentList - List of existing correspondents
   * @returns {string} - Comma-separated list of correspondent names or empty string
   */
  static _formatCorrespondentsList(existingCorrespondentList) {
    if (!existingCorrespondentList) {
      return '';
    }

    if (typeof existingCorrespondentList === 'string') {
      return existingCorrespondentList.trim();
    }

    if (Array.isArray(existingCorrespondentList)) {
      return existingCorrespondentList
        .filter(Boolean)  // Remove any null/undefined entries
        .map(correspondent => {
          if (typeof correspondent === 'string') return correspondent;
          return correspondent?.name || '';
        })
        .filter(name => name.length > 0)  // Remove empty strings
        .join(', ');
    }

    return '';
  }
}

module.exports = RestrictionPromptService;
