# Google Drive Integration for Document Attachments

This Business Central extension enhances the standard Document Attachment functionality by adding the ability to store attachments in Google Drive instead of in the tenant media storage.

## Features

- Store document attachments in Google Drive instead of in Business Central's database
- Adds a "Store in Google Drive" option to Document Attachment records
- Maintains the Google Drive URL in the document attachment record
- Provides direct access to the Google Drive file via a hyperlink
- Maintains the same user experience as the standard Document Attachment functionality

## Components

1. **Table Extension**: Extends Document Attachment table with Google Drive URL and option fields
2. **Google Drive Manager**: Handles authentication and file operations with Google Drive
3. **Document Attachment Management**: Overrides standard document attachment behaviors for upload, download, and delete
4. **Page Extension**: Enhances Document Attachment Factbox with Google Drive-specific fields
5. **Event Subscribers**: Hooks into Document Attachment events to use Google Drive when specified

## Setup

To use this extension, you need to:

1. Register an application in the Google API Console and obtain credentials
2. Configure the extension with your Google API credentials
3. Set the "Store in Google Drive" option on document attachments to use Google Drive storage

## Implementation Details

### Authentication

The extension uses OAuth 2.0 to authenticate with Google Drive. To configure authentication:

1. Set up a Google API Project and enable the Drive API
2. Create OAuth credentials (Web application type)
3. Configure your redirect URI to match the OAuth Landing page in Business Central
4. Store your credentials securely (the extension uses placeholder values that need to be replaced)

### File Operations

- **Upload**: Files are uploaded to Google Drive using the Google Drive API
- **Download**: Files are retrieved from Google Drive when users want to view them
- **Delete**: Records are marked as deleted in Business Central (files remain in Google Drive)

## Limitations

In this implementation:

1. File deletion only removes the Business Central record, not the actual file in Google Drive
2. The Google Drive API credentials are placeholders and must be properly configured
3. The OAuth flow is simplified and would need enhancement for production use
4. Error handling is basic and would need improvement for production use

## Future Enhancements

Potential future improvements:

1. Implement proper file deletion from Google Drive
2. Add configuration page for Google API settings
3. Improve error handling and user feedback
4. Add support for shared drives and specific folders
5. Implement permission management for shared files

## License

This extension is provided as-is for demonstration purposes. 