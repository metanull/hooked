<?php

namespace App\Mail;

use Illuminate\Bus\Queueable;
use Illuminate\Mail\Mailable;
use Illuminate\Mail\Mailables\Content;
use Illuminate\Mail\Mailables\Envelope;
use Illuminate\Queue\SerializesModels;
use Symfony\Component\Mime\Email;

class SmtpTestMail extends Mailable
{
    use Queueable;
    use SerializesModels;

    public function __construct(
        public readonly string $subjectLine,
        public readonly string $bodyText,
        public readonly string $contentType,
        public readonly string $contentTransferEncoding,
    ) {}

    public function envelope(): Envelope
    {
        return new Envelope(
            subject: $this->subjectLine,
        );
    }

    public function content(): Content
    {
        if ($this->contentType === 'text/html') {
            return new Content(
                htmlString: $this->bodyText,
            );
        }

        return new Content(
            text: 'mail.smtp-test-text',
            with: [
                'bodyText' => $this->bodyText,
            ],
        );
    }

    public function build(): static
    {
        $this->withSymfonyMessage(function (Email $message): void {
            $headers = $message->getHeaders();

            if ($headers->has('Content-Transfer-Encoding')) {
                $headers->remove('Content-Transfer-Encoding');
            }

            $headers->addTextHeader('Content-Transfer-Encoding', $this->contentTransferEncoding);
        });

        return $this;
    }
}