<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/**
 * Picks the language from the app's Accept-Language header and translates
 * the user-facing "message" and validation "errors" of JSON responses.
 *
 * Controllers keep writing plain English; the Amharic wording lives in
 * lang/am.json (exact sentences) and lang/am/validation.php (rule messages),
 * so translators edit one place and nothing in the business logic changes.
 */
class LocalizeApiResponse
{
    public const SUPPORTED = ['en', 'am'];

    public function handle(Request $request, Closure $next): Response
    {
        $locale = substr(strtolower((string) $request->header('Accept-Language', 'en')), 0, 2);
        app()->setLocale(in_array($locale, self::SUPPORTED, true) ? $locale : 'en');

        $response = $next($request);

        if (app()->getLocale() === 'en' || ! $response instanceof JsonResponse) {
            return $response;
        }

        $data = $response->getData(true);
        if (! is_array($data)) {
            return $response;
        }

        if (isset($data['message']) && is_string($data['message'])) {
            $data['message'] = __($data['message']);
        }
        if (isset($data['errors']) && is_array($data['errors'])) {
            foreach ($data['errors'] as $field => $messages) {
                $data['errors'][$field] = array_map(
                    fn ($m) => is_string($m) ? __($m) : $m,
                    (array) $messages,
                );
            }
            // Laravel's summary line repeats the first error; keep it in step.
            $first = collect($data['errors'])->flatten()->first();
            if (is_string($first)) {
                $data['message'] = $first;
            }
        }

        $response->setData($data);

        return $response;
    }
}
