<?php

namespace App\Filament\Resources;

use App\Filament\Resources\ProfessionalProfileResource\Pages;
use App\Models\ProfessionalProfile;
use App\Notifications\ProfessionalVerifiedNotification;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Notifications\Notification;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

class ProfessionalProfileResource extends Resource
{
    protected static ?string $model = ProfessionalProfile::class;
    protected static ?string $navigationIcon = 'heroicon-o-user-circle';
    protected static ?string $navigationGroup = 'People';
    protected static ?string $modelLabel = 'Counselor';
    protected static ?string $pluralModelLabel = 'Counselors';
    protected static ?string $navigationLabel = 'Counselors';
    protected static ?int $navigationSort = 20;

    public static function form(Form $form): Form
    {
        return $form->schema([
            Forms\Components\Section::make('Profile')
                ->schema([
                    Forms\Components\TextInput::make('user.name')->label('Name')->disabled(),
                    Forms\Components\TextInput::make('user.email')->label('Email')->disabled(),
                    Forms\Components\Select::make('category_id')->relationship('category', 'name')->required(),
                    Forms\Components\TextInput::make('experience_years')->numeric()->minValue(0)->maxValue(70),
                    Forms\Components\Textarea::make('bio')->rows(3),
                ])
                ->columns(2),
            Forms\Components\Section::make('Verification')
                ->schema([
                    Forms\Components\Select::make('verification_status')
                        ->options([
                            'pending'    => 'Pending',
                            'in_review'  => 'In review',
                            'approved'   => 'Approved',
                            'rejected'   => 'Rejected',
                            'revoked'    => 'Revoked',
                        ])->required(),
                    Forms\Components\TextInput::make('rejection_reason')->visible(fn ($get) => $get('verification_status') === 'rejected'),
                    Forms\Components\Toggle::make('badge_active')
                        ->helperText('Issue the green "verified" badge.'),
                    Forms\Components\Toggle::make('is_accepting_clients')
                        ->helperText('Allow new bookings.'),
                ])
                ->columns(2),
        ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->defaultSort('id', 'desc')
            ->columns([
                Tables\Columns\TextColumn::make('id')->sortable(),
                Tables\Columns\TextColumn::make('user.name')->label('Name')->searchable(),
                Tables\Columns\TextColumn::make('user.email')->label('Email')->searchable(),
                Tables\Columns\TextColumn::make('category.name')->label('Category')->badge(),
                Tables\Columns\TextColumn::make('verification_status')
                    ->badge()
                    ->color(fn (string $state) => match ($state) {
                        'approved'  => 'success',
                        'pending'   => 'warning',
                        'rejected'  => 'danger',
                        'in_review' => 'info',
                        default     => 'gray',
                    }),
                Tables\Columns\IconColumn::make('badge_active')->boolean(),
                Tables\Columns\TextColumn::make('rating_avg')->numeric(decimalPlaces: 2),
                Tables\Columns\TextColumn::make('created_at')->dateTime()->sortable(),
            ])
            ->filters([
                Tables\Filters\SelectFilter::make('verification_status')
                    ->options([
                        'pending' => 'Pending',
                        'in_review' => 'In review',
                        'approved' => 'Approved',
                        'rejected' => 'Rejected',
                    ]),
            ])
            ->actions([
                Tables\Actions\Action::make('approve')
                    ->icon('heroicon-o-check-circle')
                    ->color('success')
                    ->visible(fn (ProfessionalProfile $r) => in_array($r->verification_status, ['pending', 'in_review']))
                    ->requiresConfirmation()
                    ->action(function (ProfessionalProfile $record) {
                        $record->update([
                            'verification_status' => 'approved',
                            'badge_active'        => true,
                            'badge_issued_at'     => now(),
                            'badge_issued_by'     => auth()->id(),
                            'is_accepting_clients'=> true,
                        ]);
                        $record->user?->notify(new ProfessionalVerifiedNotification($record));
                        Notification::make()->title('Professional approved')->success()->send();
                    }),
                Tables\Actions\Action::make('reject')
                    ->icon('heroicon-o-x-circle')
                    ->color('danger')
                    ->visible(fn (ProfessionalProfile $r) => in_array($r->verification_status, ['pending', 'in_review']))
                    ->requiresConfirmation()
                    ->form([
                        Forms\Components\TextInput::make('rejection_reason')->required(),
                    ])
                    ->action(function (ProfessionalProfile $record, array $data) {
                        $record->update([
                            'verification_status' => 'rejected',
                            'is_accepting_clients'=> false,
                        ]);
                        $record->user?->notify(new \App\Notifications\AdminMessageNotification(
                            subject: 'Your Akilil verification was not approved',
                            body: 'Reason: ' . $data['rejection_reason'],
                        ));
                        Notification::make()->title('Professional rejected')->warning()->send();
                    }),
                Tables\Actions\ViewAction::make(),
            ]);
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListProfessionalProfiles::route('/'),
            'view'  => Pages\ViewProfessionalProfile::route('/{record}'),
            'edit'  => Pages\EditProfessionalProfile::route('/{record}/edit'),
        ];
    }
}